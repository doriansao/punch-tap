"""Recover logical composition transitions at the actual $C890 call boundary.
The runtime export contains original-art IDs and geometry, no NES tile graphics.
"""
from pathlib import Path
from PIL import Image
import json,numpy as np,hashlib,collections
root=Path('research/evidence/animation');measure=json.loads((root/'measurements.json').read_text());chr=np.frombuffer(Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[131088:],dtype=np.uint8).reshape(32,256,16);bits=np.arange(7,-1,-1);tiles=((chr[:,:,:8,None]>>bits)&1)+2*((chr[:,:,8:,None]>>bits)&1)
def component(mask):
 pending=set(zip(*np.where(mask)));parts=[]
 while pending:
  seed=pending.pop();stack=[seed];part=[seed]
  while stack:
   y,x=stack.pop()
   for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
    p=y+dy,x+dx
    if p in pending:pending.remove(p);part.append(p);stack.append(p)
  parts.append(part)
 if not parts:return None,[]
 part=max(parts,key=len);y=min(p[0]for p in part);x=min(p[1]for p in part);h=max(p[0]for p in part)-y+1;w=max(p[1]for p in part)-x+1;a=np.zeros((h,w),dtype=bool)
 for yy,xx in part:a[yy-y,xx-x]=1
 return a,[int(x),int(y),int(w),int(h)]
def digest(a):return hashlib.sha256(a.tobytes()).hexdigest()[:16]if a is not None else 'empty'
known={};seen=set()
for case,t in measure.items():
 for row in t['frames']:
  p=row['opponent']
  if not p['box']or p['mask_hash']in seen:continue
  seen.add(p['mask_hash']);x,y,w,h=p['box'];im=np.array(Image.open(root/case/'opponent'/f'{row["frame"]}.png').convert('RGB'));a,_=component(np.any(im[y:y+h,x:x+w]!=im[200,16],axis=2));known[digest(a)]={k:p[k]for k in ['art_frame','art_flip','visual_pose_id']}
# Reviewed offline ROM selector 12: chin-up combo recoil, gloves at waist.
# ROM selector 28 after the raised-arm body: compact high-guard silhouette.
# Geometry/transition is ROM-executed; replacement artwork is authored.
known['c7ae710ccb7031ac']={'art_frame':3,'art_flip':False,'visual_pose_id':49}
known['cb2c45fb0da01081']={'art_frame':11,'art_flip':False,'visual_pose_id':48}
# Reviewed source IDs 23/32 lower one glove; neither is a high knee lift.
for shape in ['968a003b63bebefb','f5ff2db92872695a']:
 if shape in known: known[shape]['art_frame']=29
# Reviewed body-block composition only; other idle art aliases stay unchanged.
known['bd7da4410430e979']={'art_frame':40,'art_flip':False,'visual_pose_id':1}
known['bdcc71a94e6f3f95']={'art_frame':41,'art_flip':False,'visual_pose_id':25}
cache={};geometry={};transitions=collections.defaultdict(set);full=collections.defaultdict(set);unknown={};counts=collections.Counter();initial=None;representatives={};relative_variants=collections.defaultdict(set)
out=root/'compositor_unmapped';out.mkdir(exist_ok=True)
def pose(m):
 key=(m[0xa9],m[0x80],m[0x20c:0x300])
 if key in cache:return cache[key]
 screen=np.zeros((256,256),dtype=bool)
 for j in range(0x20c,0x300,4):
  sy,t,attr,sx=m[j:j+4];sy+=1
  if sy>=240:continue
  tile=tiles[m[0xa9],t]
  if attr&128:tile=tile[::-1]
  if attr&64:tile=tile[:,::-1]
  h=min(len(tile),256-sy);w=min(8,256-sx);screen[sy:sy+h,sx:sx+w]|=tile[:h,:w]!=0
 a,b=component(screen);shape=digest(a)
 if a is not None and shape not in known and shape not in unknown:
  unknown[shape]=1;Image.fromarray(np.uint8(a)*255).save(out/f'{shape}.png')
 cache[key]=(shape,b);return shape,b
for case in ['visual_audit','normal_knockdowns','player_getup_wide','idle_long','right_knockdowns']:
 data=(root/f'{case}_compositor.bin').read_bytes()
 for off in range(0,len(data),4100):
  pre=data[off+4:off+2052];post=data[off+2052:off+4100]
  if pre[4]!=255:continue
  before,_=pose(pre);after,b=pose(post);counts['calls']+=1
  if initial is None:initial=before
  if not b:continue
  relative_variants[after].add(tuple([b[0]-post[0xb0],b[1]-post[0xb1],b[2],b[3]]))
  representatives.setdefault(after,post)
  if after not in geometry:geometry[after]={'relative_box':[b[0]-post[0xb0],b[1]-post[0xb1],b[2],b[3]],**known.get(after,{})}
  if pre[0xa0]&128:
   k=f'{before}:{pre[0xa1]}:{pre[0xa2]}';transitions[k].add(after)
   if pre[0xa1]<128:full[f'{pre[0xa1]}:{pre[0xa2]}'].add(after)
print('relative geometry conflicts',[(k,len(v),sorted(v))for k,v in relative_variants.items()if len(v)>1])
# Expand partial-update transitions by executing the ROM compositor on actual
# observed body states. Only outputs with an already identified art/geometry
# correspondence enter production; unsupported shapes remain explicit errors.
from py65.devices.mpu6502 import MPU
program=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
expanded=0
expanded_fixtures=[]
for before,ram in representatives.items():
 for selector in list(range(0,60,2))+[128,130,192,194,196,198,200,202,204]:
  key=f'{before}:{selector}:0'
  if key in transitions:continue
  mm=list(ram)+[0]*63488;mm[0x8000:0xa000]=program[:8192];mm[0xa000:]=program[-0x6000:];mm[0xa0]=128;mm[0xa1]=selector;mm[0xa2]=0;mm[0x1fe]=254;mm[0x1ff]=127
  cpu=MPU(memory=mm);cpu.pc=0xc890;cpu.sp=253
  for _ in range(20000):
   if cpu.pc==0x7fff:break
   cpu.step()
  else:continue
  result,box=pose(bytes(mm[:2048]))
  if result in known and result not in geometry and box:
   geometry[result]={'relative_box':[box[0]-mm[0xb0],box[1]-mm[0xb1],box[2],box[3]],**known[result]}
  if before=='3a993b6d203e6938' and selector==12:
   print('combo-transition',key,result,box,flush=True)
   # Local diagnostic decoding of ROM tiles, excluded from production assets.
   diagnostic=np.zeros((256,256),dtype=np.uint8)
   for j in range(0x20c,0x300,4):
    sy,t,attr,sx=mm[j:j+4];sy+=1
    if sy>=240:continue
    tile=tiles[mm[0xa9],t]
    if attr&128:tile=tile[::-1]
    if attr&64:tile=tile[:,::-1]
    h=min(8,256-sy);w=min(8,256-sx)
    target=diagnostic[sy:sy+h,sx:sx+w];target[tile[:h,:w]!=0]=tile[:h,:w][tile[:h,:w]!=0]
   colors=np.array([[24,35,51],[245,183,123],[247,247,240],[35,55,90]],dtype=np.uint8)
   Image.fromarray(colors[diagnostic[box[1]:box[1]+box[3],box[0]:box[0]+box[2]]]).resize((box[2]*6,box[3]*6),Image.Resampling.NEAREST).save(root/'combo_12_diagnostic.png')
  if result in geometry and box and [box[0]-mm[0xb0],box[1]-mm[0xb1],box[2],box[3]]==geometry[result]['relative_box']:
   transitions[key].add(result);expanded+=1
   expanded_fixtures.append(["offline-ROM",selector,before,128,selector,0,mm[0xb0],mm[0xb1],result,box])
(root/'compositor_expanded_cases.json').write_text(json.dumps(expanded_fixtures))
print('ROM-executed additional partial transitions',expanded)
ambiguous={k:list(v)for k,v in transitions.items()if len(v)>1};print(counts,'shapes',len(geometry),'unknown',len(unknown),'transitions',len(transitions),'ambiguous',len(ambiguous))
(root/'compositor_transitions_research.json').write_text(json.dumps({'initial':initial,'geometry':geometry,'transitions':{k:list(v)for k,v in transitions.items()},'full':{k:list(v)for k,v in full.items()},'ambiguous':ambiguous,'unknown':list(unknown)},indent=2))

assert not ambiguous
assert not any(len(v)>1 for v in relative_variants.values())
assert all(len(v)==1 for v in full.values())
Path('assets/data/opponent_composition.json').write_text(json.dumps({'initial':initial,'poses':geometry,'transitions':{k:next(iter(v))for k,v in transitions.items()},'full':{k:next(iter(v))for k,v in full.items()}}))
# Independent function-boundary fixtures contain abstract incoming/outgoing poses
# plus source state and anchor. No ROM graphics enter production data.
fixtures=[]
for case in ['visual_audit','normal_knockdowns','player_getup_wide','idle_long','right_knockdowns']:
 data=(root/f'{case}_compositor.bin').read_bytes()
 for off in range(0,len(data),4100):
  pre=data[off+4:off+2052];post=data[off+2052:off+4100]
  if pre[4]!=255:continue
  before,_=pose(pre);after,b=pose(post)
  fixtures.append([case,int.from_bytes(data[off:off+4],'little'),before,pre[0xa0],pre[0xa1],pre[0xa2],pre[0xb0],pre[0xb1],after,b])
(root/'compositor_cases.json').write_text(json.dumps(fixtures,separators=(',',':')))
