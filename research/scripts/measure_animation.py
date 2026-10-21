"""Measure untouched isolated-layer PNGs. Exports numbers, never ROM artwork."""
from pathlib import Path
from PIL import Image
import numpy as np
import hashlib,json,csv
ROOT=Path(__file__).resolve().parents[1]
CASES={'visual_audit':(2295,3400),'normal_knockdowns':(2295,7200),'player_getup_wide':(4000,4550),'idle_long':(2295,3400),'right_knockdowns':(2295,7200)}
BG=np.array([21,95,217])
def player_component(mask):
 # Count presentation also draws the referee through background updates.
 # Select the connected boxer component, not all non-background pixels.
 pending=set(zip(*np.where(mask)));parts=[]
 while pending:
  seed=pending.pop();part=[seed];stack=[seed]
  while stack:
   y,x=stack.pop()
   for dy,dx in [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]:
    point=(y+dy,x+dx)
    if point in pending:pending.remove(point);stack.append(point);part.append(point)
  if len(part)>5:parts.append(part)
 if not parts:return mask
 # Mac remains near x124 in these captured first-fight cases. A referee near
 # x190-220 must not change Mac's width. Selection is scoped to these cases.
 part=max(parts,key=lambda p:len(p)/(1+((sum(x for _,x in p)/len(p)+40-124)/20)**2))
 # Glove/boot islands can be disconnected by transparent pixels. Join nearby
 # components; the referee is spatially separate from this fighter component.
 selected=list(part);remaining=[p for p in parts if p is not part]
 changed=True
 while changed:
  changed=False;ys=[p[0]for p in selected];xs=[p[1]for p in selected]
  for candidate in remaining[:]:
   cy=[p[0]for p in candidate];cx=[p[1]for p in candidate]
   if min(cx)<=max(xs)+4 and max(cx)>=min(xs)-4 and min(cy)<=max(ys)+4 and max(cy)>=min(ys)-4:
    selected.extend(candidate);remaining.remove(candidate);changed=True
 result=np.zeros_like(mask)
 for y,x in selected:result[y,x]=True
 return result
def measure(path,role,anchor):
 a=np.array(Image.open(path).convert('RGB'))
 # Player's fight-area background layer contains no ring pixels below y=90.
 # Opponent's isolated sprites include referee: restrict to fighter anchor.
 x0,x1=(40,216) if role=='player' else (max(0,anchor-52),min(256,anchor+53))
 y0=90 if role=='player' else 0
 # The arena's universal background changes during the end-of-bout fade.
 # This clear ring sample is outside both fighters in these captured cases.
 background=a[200,16]
 m=np.any(a[y0:240,x0:x1,:]!=background,axis=2)
 if role=='player':
  # Player column streams occupy world x=16..79. The count referee is a
  # separate background object; when Mac is fully off-screen it must not be
  # misidentified as the player. Include two pixels for the PPU scroll latch.
  world=(np.arange(x0,x1)+anchor)%256
  m[:,(world<14)|(world>81)]=False
  m=player_component(m)
 ys,xs=np.where(m)
 if not len(xs):return {'box':[],'tip':[],'mask_hash':''}
 box=[int(xs.min()+x0),int(ys.min()+y0),int(xs.max()-xs.min()+1),int(ys.max()-ys.min()+1)]
 # Player green is shared by gloves/trunks/boots. Uppermost green pixels are
 # a measurable reach marker, not a claim to have decoded a collision box.
 green=np.all(a==[92,228,48],axis=2) if role=='player' else np.all(a==[181,49,32],axis=2)
 gy,gx=np.where(green[y0:240,x0:x1]&m)
 tip=[]
 if len(gx):
  top=gy.min();tip=[float(np.mean(gx[gy==top])+x0),int(top+y0)]
 crop=m[ys.min():ys.max()+1,xs.min():xs.max()+1]
 return {'box':box,'tip':tip,'mask_hash':hashlib.sha256(crop.tobytes()).hexdigest()[:16]}
out={};catalog={'player':{},'opponent':{}};checks=[]
for case,(start,end) in CASES.items():
 folder=ROOT/'evidence/animation'/case
 ram=(folder/'full/ram.bin').read_bytes()
 assert len(ram)==(end-start+1)*2048
 for layer in ['player','opponent']:
  other=(folder/layer/'ram.bin').read_bytes()
  assert other==ram, f'Layer changes RAM: {case}/{layer}'
 checks.append({'case':case,'frames':end-start+1,'identical_ram_across_3_layers':True,'sha256':hashlib.sha256(ram).hexdigest()})
 ppu_states={};ppu_poses={};last_player=0
 for r in csv.DictReader((ROOT/'evidence/animation'/f'{case}_ppu.csv').open()):
  if int(r['update_pose'])<128:last_player=int(r['update_pose'])
  ppu_states[int(r['frame'])+1]=int(r['split_scroll']);ppu_poses[int(r['frame'])+1]=last_player
 frames=[]
 for f in range(start,end+1):
  b=ram[(f-start)*2048:(f-start+1)*2048]
  p=measure(folder/'player'/f'{f}.png','player',ppu_states.get(f,b[0x15]))
  if ppu_poses.get(f,0) in [58,64,65,66,67]:p={'box':[],'tip':[],'mask_hash':''} # GET UP lettering / clear commands, not a boxer pose.
  o=measure(folder/'opponent'/f'{f}.png','opponent',b[0xb0])
  p['display_pose']=ppu_poses.get(f,b[0x61])
  p.update(pose=b[0x61],state=b[0x50],cursor=b[0x53],timer=b[0x52],scroll=b[0x15],contact=b[0x58],script=b[0x54]+256*b[0x55])
  o.update(pose=f'{b[0xa3]+256*b[0xa4]:04X}:{b[0xa5]:02X}:{b[0xa6]+256*b[0xa7]:04X}',state=b[0x90],cursor=b[0x93],timer=b[0x92],anchor=[b[0xb0],b[0xb1]],selector=b[0xa1],script=b[0x94]+256*b[0x95])
  row={'frame':f,'player':p,'opponent':o}
  frames.append(row)
  for role,value in [('player',p),('opponent',o)]:
   # The actual rendered mask disambiguates DMA/background update latency.
   key=str(value['pose'])+':'+value['mask_hash']
   value['visual_key']=key
   if value['box'] and key not in catalog[role]:catalog[role][key]={'case':case,'frame':f,**value}
 out[case]={'start':start,'frames':frames}
 print(case, 'measured',len(frames),'frames',flush=True)
(ROOT/'evidence/animation/measurements.json').write_text(json.dumps(out,separators=(',',':')))
(ROOT/'evidence/animation/pose_catalog.json').write_text(json.dumps(catalog,indent=2))
(ROOT/'evidence/animation/validation.json').write_text(json.dumps(checks,indent=2))
print('Unique rendered keys:',{k:len(v) for k,v in catalog.items()})
