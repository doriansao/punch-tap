"""Reconstruct displayed opponent masks from captured OAM and CHR banks."""
from pathlib import Path
from PIL import Image
import numpy as np,json,csv,collections
root=Path('research/evidence/animation');data=json.loads((root/'measurements.json').read_text());rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[131088:]
chr=np.frombuffer(rom,dtype=np.uint8).reshape(32,256,16);bits=np.arange(7,-1,-1);tiles=((chr[:,:,:8,None]>>bits)&1)+2*((chr[:,:,8:,None]>>bits)&1)
report=collections.Counter();examples=[]
for case,track in data.items():
 raw=(root/f'{case}_ppu.bin').read_bytes();ram=(root/case/'full/ram.bin').read_bytes();states=[{k:int(v)for k,v in r.items()}for r in csv.DictReader((root/f'{case}_ppu.csv').open())]
 for row in track['frames']:
  p=row['opponent'];f=row['frame'];i=f-2295-1
  if i<0 or not p['box'] or ram[(f-track['start'])*2048+4]!=255:continue
  s=states[i];b=np.frombuffer(raw[i*4384:(i+1)*4384],dtype=np.uint8);oam=b[4128:].reshape(64,4);screen=np.zeros((256,256),dtype=bool)
  for sy,t,attr,sx in oam[3:]:
   sy=int(sy)+1;sx=int(sx);t=int(t);attr=int(attr)
   if s['large']:
    page=s['right1']if t&1 else s['left1'];t&=254;tile=np.concatenate((tiles[page,t],tiles[page,t+1]))
   else:tile=tiles[s['left0'] if sy < int(oam[2,0])+1 else s['left1'],t]
   if attr&128:tile=tile[::-1]
   if attr&64:tile=tile[:,::-1]
   h=min(len(tile),256-sy);w=min(8,256-sx)
   if h>0 and w>0:screen[sy:sy+h,sx:sx+w]|=tile[:h,:w]!=0
  x,y,w,h=p['box'];mask=screen[y:y+h,x:x+w];a=np.array(Image.open(root/case/'opponent'/f'{f}.png').convert('RGB'));actual=np.any(a[y:y+h,x:x+w]!=a[200,16],axis=2);difference=int(np.count_nonzero(mask!=actual));report['compared']+=1;report['exact'if difference==0 else'different']+=1
  if difference and len(examples)<20:examples.append([case,f,difference,s['large'],p['box']])
  p['oam_mask_difference']=difference
(root/'oam_pose_validation.json').write_text(json.dumps({'counts':dict(report),'examples':examples},indent=2));(root/'measurements.json').write_text(json.dumps(data,separators=(',',':')));print(report);print(examples)
