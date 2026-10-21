"""Match offline-composited bodies to observed poses; keep unknown shapes visible."""
from pathlib import Path
from PIL import Image,ImageDraw
import numpy as np,json,hashlib,collections
root=Path('research/evidence/animation');d=json.loads((root/'measurements.json').read_text());graph=json.loads((root/'opponent_composition_graph.json').read_text());raw=(root/'opponent_composition_states.bin').read_bytes();chr=np.frombuffer(Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[131088:],dtype=np.uint8).reshape(32,256,16);bits=np.arange(7,-1,-1);tiles=((chr[:,:,:8,None]>>bits)&1)+2*((chr[:,:,8:,None]>>bits)&1)
def digest(a):return hashlib.sha256(a.tobytes()).hexdigest()[:16]
def body(a):
 pending=set(zip(*np.where(a)));parts=[]
 while pending:
  seed=pending.pop();part=[seed];stack=[seed]
  while stack:
   y,x=stack.pop()
   for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
    q=y+dy,x+dx
    if q in pending:pending.remove(q);part.append(q);stack.append(q)
  parts.append(part)
 part=max(parts,key=len);ys=[p[0]for p in part];xs=[p[1]for p in part];x,y,w,h=min(xs),min(ys),max(xs)-min(xs)+1,max(ys)-min(ys)+1
 mask=np.zeros((h,w),dtype=bool)
 for yy,xx in part:mask[yy-y,xx-x]=1
 return mask,[x,y,w,h]
known={}
for case,t in d.items():
 for r in t['frames']:
  o=r['opponent'];k=o['mask_hash']
  if not o['box']or k in known:continue
  x,y,w,h=o['box'];a=np.array(Image.open(root/case/'opponent'/f'{r["frame"]}.png').convert('RGB'));mask=np.any(a[y:y+h,x:x+w]!=a[200,16],axis=2)
  mask,_=body(mask)
  known[k]=1;known[digest(mask)]={'art_frame':o['art_frame'],'art_flip':o['art_flip'],'visual_pose_id':o['visual_pose_id']}
result=[];unknown={};out=root/'composition_catalog';out.mkdir(exist_ok=True)
for i in range(len(raw)//2048):
 m=raw[i*2048:(i+1)*2048];a=np.zeros((256,256),dtype=bool)
 for j in range(0x20c,0x300,4):
  sy,t,attr,sx=m[j:j+4];sy+=1
  if sy>=240:continue
  tile=tiles[m[0xa9],t]
  if attr&128:tile=tile[::-1]
  if attr&64:tile=tile[:,::-1]
  h=min(8,256-sy);w=min(8,256-sx);a[sy:sy+h,sx:sx+w]|=tile[:h,:w]!=0
 mask,b=body(a);key=digest(mask);mapping=known.get(key)
 if not isinstance(mapping,dict):mapping=None;unknown.setdefault(key,[]).append(i)
 result.append({'relative_box':[b[0]-m[0xb0],b[1]-m[0xb1],b[2],b[3]],'shape':key,'mapping':mapping})
 if key not in [r['shape']for r in result[:-1]]:
  im=Image.fromarray(np.uint8(mask)*255).convert('RGB');im.save(out/f'{key}.png')
(root/'composition_geometry.json').write_text(json.dumps(result,indent=2,default=lambda v:int(v)));print('states',len(result),'unique bodies',len({r['shape']for r in result}),'unknown bodies',len(unknown),'unknown states',sum(map(len,unknown.values())))
for page in range(0,len(unknown),24):
 im=Image.new('RGB',(960,720),'#182333');draw=ImageDraw.Draw(im)
 for j,(key,ids) in enumerate(list(unknown.items())[page:page+24]):
  p=Image.open(out/f'{key}.png');p.thumbnail((140,145));x=(j%6)*160;y=(j//6)*180;im.paste(p,(x+(160-p.width)//2,y+25));draw.text((x+4,y+3),f'{ids[0]} {graph["origins"][ids[0]]}',fill='white')
 im.save(out/f'unknown_{page}.png')

