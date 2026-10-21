from pathlib import Path
import json,csv,hashlib,collections
root=Path('research/evidence/animation');d=json.loads((root/'measurements.json').read_text());matched=missing=0;catalog={};pgeom={};ogeom={};initial={}
for case,track in d.items():
 ram=(root/case/'full/ram.bin').read_bytes();ppu=(root/f'{case}_ppu.bin').read_bytes();states=[{k:int(v)for k,v in r.items()}for r in csv.DictReader((root/f'{case}_ppu.csv').open())]
 for idx,row in enumerate(track['frames']):
  f=row['frame'];j=f-2296
  if j<0:continue
  actual=ppu[j*4384+4128:(j+1)*4384];source=None
  for k in range(idx,max(-1,idx-5),-1):
   candidate=ram[k*2048:(k+1)*2048]
   shadow=bytearray(candidate[0x200:0x300])
   for a in range(2,256,4):shadow[a]&=0xe3 # OAM attribute bits 2..4 are physically absent.
   if shadow==actual:source=candidate;break
  p=row['player'];o=row['opponent']
  if source:
   matched+=1;o['display_selector']=source[0xa1];o['display_anchor']=[source[0xb0],source[0xb1]]
   key=str(source[0xa1])
   if o['box'] and key not in ogeom:
    g=dict(o);x,y,w,h=g['box'];g['relative_box']=[x-source[0xb0],y-source[0xb1],w,h];ogeom[key]=g
  else:missing+=1
  if p['box'] and p.get('ppu_mask_difference')==0 and p.get('display_pose',-1)>=0:
   key=str(p['display_pose'])
   if key not in pgeom:
    g=dict(p);s=states[j];g['world_box']=[(p['draw_box'][0]+s['split_scroll'])%256,*p['draw_box'][1:]];pgeom[key]=g
(root/'measurements.json').write_text(json.dumps(d,separators=(',',':')))
# Numeric initial state of the first-fight reference, not ROM data.
b=(root/'idle_long/full/ram.bin').read_bytes()[:2048]
addresses=list(range(0xe0))+list(range(0x300,0x400))+list(range(0x480,0x600))
initial={str(a):b[a]for a in addresses}
Path('assets/data/animation_geometry.json').write_text(json.dumps({'player':pgeom,'opponent':ogeom,'initial':initial},separators=(',',':')))
print('OAM producer matches',matched,'missing',missing,'geometry',len(pgeom),len(ogeom))
