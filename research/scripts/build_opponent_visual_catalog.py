from pathlib import Path
from PIL import Image,ImageDraw
import json
root=Path('research/evidence/animation');m=json.loads((root/'measurements.json').read_text());catalog={}
for case,c in m.items():
 for row in c['frames']:
  p=row['opponent'];key=p['mask_hash']
  if key and key not in catalog:catalog[key]={'id':len(catalog),'case':case,'frame':row['frame'],**p}
for first in range(0,len(catalog),20):
 sheet=Image.new('RGB',(1200,960),'#203040');d=ImageDraw.Draw(sheet)
 for p in list(catalog.values())[first:first+20]:
  i=p['id']-first;x,y,w,h=p['box'];im=Image.open(root/p['case']/'opponent'/f'{p["frame"]}.png').crop((x,y,x+w,y+h));s=min(200/w,185/h);im=im.resize((int(w*s),int(h*s)),Image.Resampling.NEAREST);cx=i%5*240;cy=i//5*240;sheet.paste(im,(cx+(240-im.width)//2,cy+45));d.text((cx+8,cy+8),f'ID {p["id"]} / {p["pose"]}',fill='white')
 sheet.save(root/f'opponent_catalog_{first}.png')
(root/'opponent_visual_catalog.json').write_text(json.dumps(catalog,indent=2))
