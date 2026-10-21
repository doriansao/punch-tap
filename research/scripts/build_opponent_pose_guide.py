from pathlib import Path
from PIL import Image,ImageDraw
import json
m=json.loads(Path('assets/data/animation_tracks.json').read_text());points=[('jab',18),('jab',46),('cross',60),('reaction_left',7),('taunt_long',40),('opponent_down',80),('opponent_down',400),('opponent_down',660)];sheet=Image.new('RGB',(1536,1024),'#203040');d=ImageDraw.Draw(sheet);meta=[]
for i,(clip,age)in enumerate(points):
 c=m[clip];r=c['frames'][age];p=r['opponent'];x,y,w,h=p['box'];im=Image.open(f'research/evidence/animation/{c["case"]}/opponent/{r["frame"]}.png').crop((x,y,x+w,y+h));s=min(320/w,420/h);im=im.resize((int(w*s),int(h*s)),Image.Resampling.NEAREST);cx=i%4*384;cy=i//4*512;sheet.paste(im,(cx+(384-im.width)//2,cy+60));d.text((cx+10,cy+10),f'Cell {i}: {clip} + {age}',fill='white');meta.append({'cell':i,'clip':clip,'age':age,'pose':p['pose']})
sheet.save('research/evidence/animation/opponent_motion_guide.png');Path('research/evidence/animation/opponent_motion_guide.json').write_text(json.dumps(meta,indent=2))
