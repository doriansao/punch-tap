"""Check component draw coverage and atlas bounds without changing pixels."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
data=json.loads((ROOT/'assets/data/art_registration.json').read_text(encoding='utf-8'))
count=0
for role,rows in data.items():
 for i,row in enumerate(rows):
  w,h=row['region'][2:];area=0;occupied=set()
  for x,y,rw,rh in row['draw_spans']:
   assert rw>0 and rh>0 and x>=0 and y>=0 and x+rw<=w and y+rh<=h,(role,i,'bounds')
   area+=rw*rh
   for yy in range(y,y+rh):
    for xx in range(x,x+rw):
     key=yy*w+xx
     assert key not in occupied,(role,i,'overlapping triangles')
     occupied.add(key)
  assert area==row['alpha_component_area'],(role,i,area,row['alpha_component_area'])
  count+=1
print(f'Atlas geometry: {count} component meshes, exact component area, no overlapping draw spans')
