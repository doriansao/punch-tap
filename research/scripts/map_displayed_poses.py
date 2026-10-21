from pathlib import Path
from PIL import Image
import numpy as np,json,hashlib,collections
root=Path('research/evidence/animation');m=json.loads((root/'measurements.json').read_text());keys={};templates={}
for file in(root/'decoded_player').glob('[0-9][0-9][0-9].png'):
 a=np.array(Image.open(file))[:,:,3]>0;y,x=np.where(a)
 if len(x):
  a=a[y.min():y.max()+1,x.min():x.max()+1];templates[int(file.stem)]=a;keys.setdefault(hashlib.sha256(a.tobytes()).hexdigest()[:16],[]).append(int(file.stem))
counters=collections.Counter();miss=collections.Counter();examples=[]
for case,c in m.items():
 for i,row in enumerate(c['frames']):
  p=row['player'];key=p['mask_hash'];candidates=keys.get(key,[]);kind='exact decoded silhouette'
  if not p['box']:p['display_pose']=-1;p['pose_evidence']='empty';counters['empty']+=1;continue
  if not candidates:
   x,y,w,h=p['box'];a=np.array(Image.open(root/case/'player'/f'{row["frame"]}.png').convert('RGB'));mask=np.any(a[y:y+h,x:x+w]!=a[200,16],axis=2);candidates=keys.get(hashlib.sha256(mask.tobytes()).hexdigest()[:16],[])
  if not candidates:
   x,y,w,h=p['box'];kind='exact clipped decoded silhouette'
   for pose,a in templates.items():
    if a.shape[1]!=w or a.shape[0]<h:continue
    if (y+h==240 and np.array_equal(mask,a[:h])) or(y==0 and np.array_equal(mask,a[-h:])):candidates.append(pose)
  if not candidates:
   counters['unmatched']+=1;miss[p['pose']]+=1
   if len(examples)<30:examples.append([case,row['frame'],p['pose'],p['box']])
   p['display_pose']=int(c['frames'][max(0,i-2)]['player']['pose']);p['pose_evidence']='unresolved composite; two-frame pending-update candidate'
  else:
   recent=[int(c['frames'][max(0,i-j)]['player']['pose'])for j in [2,1,0,3]]
   p['display_pose']=next((v for v in recent if v in candidates),candidates[0]);p['pose_evidence']=kind;counters[kind]+=1
(root/'measurements.json').write_text(json.dumps(m,separators=(',',':')));(root/'display_pose_validation.json').write_text(json.dumps({'counts':dict(counters),'unmatched_by_selector':dict(miss),'examples':examples},indent=2));print(counters);print(miss);print(examples[:6])
