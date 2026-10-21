"""Recover offscreen extent only when an observed full silhouette matches exactly."""
from pathlib import Path
from PIL import Image
import numpy as np,json
root=Path(__file__).resolve().parents[1]/'evidence/animation'
data=json.loads((root/'measurements.json').read_text());bg=np.array([21,95,217])
templates={'player':{},'opponent':{}}
def mask(case,frame,role,box):
 x,y,w,h=box;a=np.array(Image.open(root/case/role/f'{frame}.png').convert('RGB'))
 return np.any(a[y:y+h,x:x+w]!=a[200,16],axis=2)
for case,track in data.items():
 for row in track['frames']:
  for role in templates:
   actor=row[role];box=actor['box']
   if not box or box[1]<=0 or box[1]+box[3]>=240:continue
   key=actor['mask_hash']
   if key not in templates[role]:templates[role][key]=mask(case,row['frame'],role,box)
# Include decoded column streams even when their last opaque row is y=239.
# Touching the viewport edge does not prove that a complete pose was clipped.
for file in (root/'decoded_player').glob('[0-9][0-9][0-9].png'):
 a=np.array(Image.open(file))[:,:,3]>0;yy,xx=np.where(a)
 if len(xx):templates['player']['rom_column_stream_'+file.stem]=a[yy.min():yy.max()+1,xx.min():xx.max()+1]
report={'recovered':0,'unresolved':0,'ambiguous_examples':[]};cache={}
for case,track in data.items():
 for row in track['frames']:
  for role in templates:
   actor=row[role];box=actor['box'];actor['draw_box']=box;actor['crop_y']=[0.0,1.0]
   if not box or (box[1]>0 and box[1]+box[3]<240):continue
   x,y,w,h=box;key=(role,actor['mask_hash'],y==0)
   # The ROM deliberately stores only the visible head/torso during rising.
   # Match that prefix inside its complete ROM pose family, including the
   # horizontal inset. Matching only equal widths shrinks the entire boxer.
   pose=int(actor.get('display_pose',-1));family=None
   if role=='player':
    if 54<=pose<=57:family=54
    elif 60<=pose<=63:family=60
    elif 72<=pose<=77:family=78+(pose%2)
   if role=='player' and 68<=pose<=71:
    # These four unique visible prefixes have no stored full-body counterpart.
    # Keep original art at the 61-pixel standing scale; lower anatomy remains
    # off-screen. This is art registration, not recovered hidden ROM pixels.
    fw=24 if pose%2==0 else 26;inset=(fw-w)//2
    actor['draw_box']=[x-inset,y,fw,61];actor['crop_y']=[0.0,h/61];actor['extent_evidence']='ROM stores a unique visible prefix only; original art uses explicit 61-pixel standing registration behind viewport crop';report['recovered']+=1;continue
   if family is not None:
    full=templates['player']['rom_column_stream_'+f'{family:03}'];part=mask(case,row['frame'],role,box);section=full[:h];yy,xx=np.where(section)
    if len(xx):
     inset=int(xx.min());section=section[:,inset:int(xx.max())+1]
     if np.array_equal(section,part):
      fh,fw=full.shape;actor['draw_box']=[x-inset,y,fw,fh];actor['crop_y']=[0.0,h/fh];actor['extent_evidence']=f'exact visible prefix of decoded pose {family}, horizontal inset {inset}; hidden pixels are a compatible full-pose continuation';report['recovered']+=1;continue

   if key not in cache:
    part=mask(case,row['frame'],role,box);heights=set();candidates=[]
    for full in templates[role].values():
     fh,fw=full.shape
     if fw!=w or fh<h:continue
     section=full[-h:] if y==0 else full[:h]
     if np.array_equal(section,part):heights.add(fh);candidates.append(full)
    # A ROM stream can itself be a deliberate prefix (fall/get-up).
    # Collapse nested candidates only after comparing every pixel, not by
    # blindly choosing the tallest unrelated body.
    if candidates:
     longest=max(candidates,key=lambda a:a.shape[0])
     if all(np.array_equal(c,longest[-len(c):] if y==0 else longest[:len(c)]) for c in candidates):heights={len(longest)}
    cache[key]=sorted(heights)
   heights=cache[key]
   if len(heights)==1:
    full_h=heights[0];top=y-(full_h-h) if y==0 else y
    actor['draw_box']=[x,top,w,full_h]
    actor['crop_y']=[(y-top)/full_h,h/full_h]
    actor['extent_evidence']='exact prefix/suffix match to observed silhouette or decoded ROM column stream'
    report['recovered']+=1
   else:
    actor['extent_evidence']='unresolved offscreen extent; visible measurement only'
    report['unresolved']+=1
    if len(report['ambiguous_examples'])<20:report['ambiguous_examples'].append([case,row['frame'],role,heights])
(root/'measurements.json').write_text(json.dumps(data,separators=(',',':')))
(root/'clipping_validation.json').write_text(json.dumps(report,indent=2))
print(report)
