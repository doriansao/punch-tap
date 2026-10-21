"""Separate opponent body bounds from source particle islands before art fitting."""
from pathlib import Path
from PIL import Image
import numpy as np,json
root=Path('research/evidence/animation');d=json.loads((root/'measurements.json').read_text());catalog=json.loads((root/'opponent_visual_catalog.json').read_text());cache={};changed=0
for case,track in d.items():
 for row in track['frames']:
  p=row['opponent'];key=p['mask_hash'];p['visual_pose_id']=catalog[key]['id']if key in catalog else -1
  if not p['box']:continue
  if key not in cache:
   x,y,w,h=p.get('composition_box',p['box']);im=np.array(Image.open(root/case/'opponent'/f'{row["frame"]}.png').convert('RGB'));mask=np.any(im[y:y+h,x:x+w]!=im[200,16],axis=2);pending=set(zip(*np.where(mask)));parts=[]
   while pending:
    seed=pending.pop();part=[seed];stack=[seed]
    while stack:
     yy,xx=stack.pop()
     for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
      q=yy+dy,xx+dx
      if q in pending:pending.remove(q);part.append(q);stack.append(q)
    parts.append(part)
   parts.sort(key=len,reverse=True);body=parts[0];yy=[q[0]for q in body];xx=[q[1]for q in body];box=[min(xx),min(yy),max(xx)-min(xx)+1,max(yy)-min(yy)+1]
   effects=[]
   for part in parts[1:]:
    yy=[q[0]for q in part];xx=[q[1]for q in part];effects.append([sum(xx)/len(xx),sum(yy)/len(yy),len(part)])
   cache[key]=(box,effects)
  old=p.get('composition_box',p['box']);box,effects=cache[key];p['composition_box']=old;p['box']=[old[0]+box[0],old[1]+box[1],box[2],box[3]];p['draw_box']=p['box'];p['crop_y']=[0,1];p['effects']=[[old[0]+x,old[1]+y,area]for x,y,area in effects]
  if p['box']!=old:changed+=1
(root/'measurements.json').write_text(json.dumps(d,separators=(',',':'),default=lambda x:x.item()));print('Separated particle islands in',changed,'opponent frames;',len(cache),'visual shapes')

