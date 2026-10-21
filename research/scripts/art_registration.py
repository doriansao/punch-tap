"""Read original artwork alpha/colour only; never modify image pixels."""
from PIL import Image
from pathlib import Path
import numpy as np,json
root=Path(__file__).resolve().parents[2]
regions={
 'player':[(0,0,384,492),(384,0,384,492),(768,0,384,488),(1152,0,384,500),(0,492,384,532),(384,512,384,512),(768,488,384,536),(1152,512,384,512)],
 'opponent':[(0,0,384,512),(384,0,384,512),(768,0,384,512),(1152,0,384,512),(0,520,384,504),(384,520,400,504),(800,520,352,504),(1152,520,384,504)]}
out={}
for role,name in [('player','teo_rear.png'),('opponent','nico_front.png')]:
 im=np.array(Image.open(root/'assets'/name));frames=[]
 for x,y,w,h in regions[role]:
  a=im[y:y+h,x:x+w];ys,xs=np.where(a[:,:,3]>24)
  lx,ty,rx,by=map(int,[xs.min(),ys.min(),xs.max()+1,ys.max()+1])
  p=a[ty:by,lx:rx];r=p[:,:,0].astype(int);g=p[:,:,1].astype(int);b=p[:,:,2].astype(int)
  mask=(g>r+12)&(b>r+5)&(g>90) if role=='player' else (r>g*1.7)&(r>b*1.3)&(r>130)
  mask &= p[:,:,3]>128
  gy,gx=np.where(mask)
  top=int(gy.min());sel=gy<=top+2
  frames.append({'region':[x+lx,y+ty,rx-lx,by-ty],'tip':[float(np.mean(gx[sel])),float(top)]})
 out[role]=frames
(root/'assets/data/art_registration.json').write_text(json.dumps(out,indent=2))
print('Registered alpha bounds and glove-colour landmarks for 16 original poses')
