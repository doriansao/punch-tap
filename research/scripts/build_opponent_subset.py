from pathlib import Path
from PIL import Image,ImageDraw
import json,sys
root=Path('research/evidence/animation');catalog={v['id']:v for v in json.loads((root/'opponent_visual_catalog.json').read_text()).values()};ids=[int(x)for x in sys.argv[2:]];sheet=Image.new('RGB',(1536,1024),'#203040');d=ImageDraw.Draw(sheet)
for i,key in enumerate(ids):
 p=catalog[key];x,y,w,h=p['box'];im=Image.open(root/p['case']/'opponent'/f'{p["frame"]}.png').crop((x,y,x+w,y+h));s=min(310/w,420/h);im=im.resize((int(w*s),int(h*s)),Image.Resampling.NEAREST);cx=i%4*384;cy=i//4*512;sheet.paste(im,(cx+(384-im.width)//2,cy+60));d.text((cx+10,cy+10),f'Cell {i}: source ID {key}',fill='white')
sheet.save(root/(sys.argv[1]+'.png'))
