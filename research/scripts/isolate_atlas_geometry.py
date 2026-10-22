"""Measure connected-alpha draw spans; never modifies source image pixels."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
def isolate(a,region):
 x,y,w,h=region;mask=a[y:y+h,x:x+w,3]>24
 parents=[];runs=[];previous=[]
 def find(i):
  while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
  return i
 for yy,row in enumerate(mask):
  edges=np.diff(np.r_[False,row,False].astype(np.int8));current=[]
  for l,r in zip(np.where(edges==1)[0],np.where(edges==-1)[0]):
   i=len(parents);parents.append(i);runs.append((int(l),yy,int(r)));current.append((l,r,i))
   for pl,pr,pi in previous:
    if pl<=r and pr>=l:parents[find(i)]=find(pi)
  previous=current
 groups={}
 for i,run in enumerate(runs):groups.setdefault(find(i),[]).append(run)
 keep=max(groups.values(),key=lambda rs:sum(r-l for l,_,r in rs))
 # Merge equal adjacent scanlines into textured rectangles.
 rects=[];last={}
 for l,yy,r in keep:
  key=(l,r);idx=last.get(key)
  if idx is not None and rects[idx][1]+rects[idx][3]==yy:rects[idx][3]+=1
  else:last[key]=len(rects);rects.append([l,yy,r-l,1])
 foreign=int(mask.sum())-sum(r-l for l,_,r in keep)
 return rects,foreign
if __name__=='__main__':
 p=ROOT/'assets/data/art_registration.json';data=json.loads(p.read_text(encoding='utf-8'));images={};report=[]
 for role,frames in data.items():
  for i,row in enumerate(frames):
   path=row['texture'].removeprefix('res://')
   if path not in images:images[path]=np.array(Image.open(ROOT/path).convert('RGBA'))
   row['draw_spans'],foreign=isolate(images[path],row['region'])
   if foreign:report.append({'role':role,'frame':i,'foreign_pixels_removed_from_draw':foreign})
 p.write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
 out=ROOT/'research/evidence/atlas_isolation.json';out.write_text(json.dumps(report,indent=2),encoding='utf-8')
 print('Isolated',sum(len(v) for v in data.values()),'registrations;',len(report),'contaminated rectangles',sum(r['foreign_pixels_removed_from_draw'] for r in report),'foreign pixels excluded')
