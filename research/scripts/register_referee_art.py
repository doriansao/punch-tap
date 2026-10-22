"""Register six original referee poses without editing pixels."""
from pathlib import Path
import ast,json
import numpy as np
from PIL import Image
from isolate_atlas_geometry import isolate
ROOT=Path(__file__).resolve().parents[2]
tree=ast.parse((ROOT/'research/scripts/register_recovered_art.py').read_text(encoding='utf-8'))
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)],type_ignores=[]),'<components>','exec'))
a=np.array(Image.open(ROOT/'assets/cartoon/production/referee_v1.png').convert('RGBA'));rows={}
for x,y,r,b,area in components(a[:,:,3]>24)[:6]:
 key=min(2,int((x+r)/2/(a.shape[1]/3)))+3*min(1,int((y+b)/2/(a.shape[0]/2)))
 assert key not in rows
 region=[x,y,r-x,b-y];spans,_=isolate(a,region)
 rows[key]={'texture':'res://assets/cartoon/production/referee_v1.png','region':region,'draw_spans':spans}
assert len(rows)==6
extra=np.array(Image.open(ROOT/'assets/cartoon/production/referee_arm_loop_v1.png').convert('RGBA'))
parts=sorted(components(extra[:,:,3]>24)[:3],key=lambda c:c[0])
core_height=parts[0][3]-parts[0][1]
for i,(x,y,r,b,area) in enumerate(parts):
 region=[x,y,r-x,b-y];spans,_=isolate(extra,region)
 # Shared body height, not total bounds: the raised hand must not shrink him.
 feet=extra[b-15:b,x:r,3]>24
 _,fx=np.where(feet)
 rows[6+i]={'texture':'res://assets/cartoon/production/referee_arm_loop_v1.png','region':region,'draw_spans':spans,'body_height':core_height,'foot_x':float((fx.min()+fx.max())/2)}
(ROOT/'assets/data/referee_art.json').write_text(json.dumps([rows[i] for i in range(9)]),encoding='utf-8')
print('Registered 9 referee component meshes')
