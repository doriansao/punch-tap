"""Validate displayed player composition from captured PPU memory, not RAM pose guesses."""
from pathlib import Path
from PIL import Image
import numpy as np,json,csv,collections
root=Path('research/evidence/animation');data=json.loads((root/'measurements.json').read_text());rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[131088:]
chr=np.frombuffer(rom,dtype=np.uint8).reshape(32,256,16);bits=np.arange(7,-1,-1)
tiles=((chr[:,:,:8,None]>>bits)&1)+2*((chr[:,:,8:,None]>>bits)&1)
report=collections.Counter();examples=[]
for case,track in data.items():
 ram=(root/case/'full/ram.bin').read_bytes();last_player_pose=0
 raw=(root/f'{case}_ppu.bin').read_bytes();states=[{k:int(v)for k,v in r.items()}for r in csv.DictReader((root/f'{case}_ppu.csv').open())]
 for row in track['frames']:
  p=row['player'];f=row['frame'];index=f-2295-1
  if ram[(f-track['start'])*2048+4]!=255:
   report['excluded_nonfight']+=1;continue
  if index<0:continue
  s=states[index]
  if s['update_pose']<128:last_player_pose=s['update_pose']
  p['display_pose']=last_player_pose
  p['pose_evidence']='captured PPU update stream and sprite-zero scroll latch'
  b=np.frombuffer(raw[index*4384:(index+1)*4384],dtype=np.uint8);nt=b[:960].reshape(30,32);world=tiles[s['right1'],nt].transpose(0,2,1,3).reshape(240,256)
  x,y,w,h=p['box']if p['box']else[0,0,0,0]
  if not w:continue
  xx=(np.arange(x,x+w)+s['split_scroll'])%256;mask=world[y:y+h][:,xx]!=0
  a=np.array(Image.open(root/case/'player'/f'{f}.png').convert('RGB'));actual=np.any(a[y:y+h,x:x+w]!=a[200,16],axis=2)
  differences=int(np.count_nonzero(mask!=actual))
  report['compared']+=1;report['exact'if differences==0 else 'different']+=1
  if differences and len(examples)<20:examples.append([case,f,differences,s['update_pose'],p['pose'],[x,y,w,h]])
  p['ppu_display_pose']=s['update_pose'];p['ppu_destination']=s['destination'];p['ppu_stream']=s['stream'];p['ppu_mask_difference']=differences
(root/'ppu_pose_validation.json').write_text(json.dumps({'counts':dict(report),'examples':examples},indent=2));(root/'measurements.json').write_text(json.dumps(data,separators=(',',':')));print(report);print(examples)
