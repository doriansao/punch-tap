"""Register original atlas components without modifying image pixels."""
from pathlib import Path
from PIL import Image
import numpy as np,json
root=Path(__file__).resolve().parents[2]
def components(mask):
 parents=[];runs=[];previous=[]
 def find(i):
  while parents[i]!=i:parents[i]=parents[parents[i]];i=parents[i]
  return i
 for y,row in enumerate(mask):
  edges=np.diff(np.r_[False,row,False].astype(np.int8));starts=np.where(edges==1)[0];ends=np.where(edges==-1)[0];current=[]
  for l,r in zip(starts,ends):
   idx=len(parents);parents.append(idx);runs.append((int(l),y,int(r)));current.append((l,r,idx))
   for pl,pr,pi in previous:
    if pl<=r and pr>=l:parents[find(idx)]=find(pi)
  previous=current
 groups={}
 for i,(l,y,r)in enumerate(runs):
  key=find(i)
  if key not in groups:groups[key]=[l,y,r,y+1,0]
  g=groups[key];g[0]=min(g[0],l);g[1]=min(g[1],y);g[2]=max(g[2],r);g[3]=max(g[3],y+1);g[4]+=r-l
 return sorted(groups.values(),key=lambda g:g[4],reverse=True)
out=json.loads((root/'assets/data/art_registration.json').read_text())
for role,base in [('player','teo_rear.png'),('opponent','nico_front.png')]:
 out[role]=out[role][:8]
 for frame in out[role]:frame['texture']='res://assets/'+base
for role,name in [('player','teo_recovered_motion.png'),('player','teo_recovered_attacks.png'),('player','teo_recovered_stances.png'),('opponent','nico_recovered_motion.png'),('opponent','nico_recovered_reactions.png'),('opponent','nico_recovered_stances.png'),('player','teo_recovered_finish.png'),('opponent','nico_recovered_finish.png'),('player','teo_recovered_rise.png')]:
 a=np.array(Image.open(root/'assets'/name));count=4 if name in ['teo_recovered_finish.png','teo_recovered_rise.png']else 8;cols=count//2;boxes=components(a[:,:,3]>24)[:count];assert len(boxes)==count
 ordered={}
 for x,y,r,b,area in boxes:
  col=min(cols-1,int((x+r)/2/(a.shape[1]/cols)));row=min(1,int((y+b)/2/(a.shape[0]/2)));key=row*cols+col;assert key not in ordered,(name,key)
  pix=a[y:b,x:r];red=pix[:,:,0].astype(int);green=pix[:,:,1].astype(int);blue=pix[:,:,2].astype(int)
  mask=(green>red+12)&(blue>red+5)&(green>90)if role=='player'else(red>green*1.7)&(red>blue*1.3)&(red>130)
  mask&=pix[:,:,3]>128;gy,gx=np.where(mask);top=int(gy.min())if len(gy)else 0;tip=[float(np.mean(gx[gy<=top+2])),top]if len(gy)else []
  ordered[key]={'texture':'res://assets/'+name,'region':[x,y,r-x,b-y],'tip':tip,'alpha_component_area':area}
 out[role].extend(ordered[i]for i in range(count));print(name,[(i,ordered[i]['region'])for i in range(count)])
(root/'assets/data/art_registration.json').write_text(json.dumps(out,indent=2))
