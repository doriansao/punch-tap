"""Decode bank-11 background pose column streams ($8020-$8118).
ROM-derived pixels are strictly local research artifacts, never game assets.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[2]
r=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes();prg=r[16:131088];chr=r[131088:];bank=prg[11*8192:12*8192]
def rd(a):return bank[a-0x8000]
def word(a):return rd(a)+256*rd(a+1)
def decode(pose):
 pointer=word((0x8800 if pose<128 else 0x88c4)+(pose&127)*2)
 dest=word(0x8a3f+rd(pointer));p=word(pointer+1);start=p
 x=dest&31;y=(dest&1023)//32;col=0;row=0;tiles=[]
 while True:
  v=rd(p);p+=1
  if v:
   tiles.append((x+col,y+row,v));row+=1;continue
  v=rd(p);p+=1
  if v==253:page=rd(p);p+=1;break
  if v==254:
   count=rd(p);first=rd(p+1);p+=2
   for i in range(count):tiles.append((x+col,y+row,(first+i)&255));row+=1
   continue
  col+=1;row=0;p-=1
  if len(tiles)>1024:raise ValueError(pose)
 pixels=np.zeros((320,256),dtype=np.uint8)
 for tx,ty,tile in tiles:
  if ty>=40:continue
  b=chr[page*4096+tile*16:page*4096+tile*16+16]
  for yy in range(8):
   for xx in range(8):pixels[ty*8+yy,(tx*8+xx)%256]=((b[yy]>>(7-xx))&1)+2*((b[yy+8]>>(7-xx))&1)
 yy,xx=np.where(pixels)
 box=[int(xx.min()),int(yy.min()),int(xx.max()-xx.min()+1),int(yy.max()-yy.min()+1)] if len(xx) else []
 return {'pose':pose,'descriptor':pointer,'stream':start,'end':p,'chr_page':page,'destination':dest,'tiles':tiles,'box':box},pixels
out=root/'research/evidence/animation/decoded_player';out.mkdir(exist_ok=True)
metadata={};images={}
for pose in list(range(98))+list(range(128,142)):
 try:meta,pix=decode(pose)
 except (IndexError,ValueError):continue
 metadata[str(pose)]=meta
 # False colors distinguish 2-bit CHR indices without borrowing palette data.
 lut=np.array([[0,0,0,0],[220,170,120,255],[30,30,40,255],[60,220,110,255]],dtype=np.uint8)
 im=Image.fromarray(lut[pix]);im.save(out/f'{pose:03}.png');images[pose]=im
(root/'research/evidence/animation/player_compositor.json').write_text(json.dumps(metadata,indent=2))
for first in range(0,98,24):
 sheet=Image.new('RGB',(960,760),'#203040');d=ImageDraw.Draw(sheet)
 for i,pose in enumerate(range(first,min(98,first+24))):
  if pose not in images:continue
  b=metadata[str(pose)]['box'];x=(i%8)*120;y=(i//8)*250
  d.text((x+5,y+5),f'pose {pose}',fill='white')
  if b:
   bx,by,w,h=b;im=images[pose].crop((bx,by,bx+w,by+h));scale=min(3,100/w,210/h);im=im.resize((int(w*scale),int(h*scale)),Image.Resampling.NEAREST);sheet.paste(im,(x+10,y+30),im)
 sheet.save(out/f'catalog_{first:03}.png')
print('Decoded',len(metadata),'pose descriptors with original column lengths and CHR page switches')
