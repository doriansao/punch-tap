"""Measure generated UI alpha regions; never changes bitmap pixels."""
from pathlib import Path
import ast,json,numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[2]
tree=ast.parse((root/'research/scripts/register_recovered_art.py').read_text())
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n,ast.FunctionDef)],type_ignores=[]),'<components>','exec'))
a=np.array(Image.open(root/'assets/cartoon/interface/controls_v1.png').convert('RGBA'))
boxes=components(a[:,:,3]>24)[:8]
assert len(boxes)==8
ordered=sorted(boxes,key=lambda b:(0 if (b[1]+b[3])/2<a.shape[0]*.54 else 1,b[0]))
names=['stick_base','stick_cap','left','right','special','bar','heart','pause']
rows={name:[x,y,r-x,b-y] for name,(x,y,r,b,area) in zip(names,ordered)}
(root/'assets/cartoon/interface/regions.json').write_text(json.dumps(rows,indent=2)+'\n',encoding='utf-8')
print(rows)
