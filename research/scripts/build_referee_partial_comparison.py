"""Compare isolated ROM-executed referee writes with original-art Godot renders."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[2];out=root/'research/evidence/referee_partial'
(out/'rom').mkdir(parents=True,exist_ok=True)
d=json.loads((root/'research/evidence/animation/player_compositor.json').read_text())
data=json.loads((root/'research/evidence/animation/referee_partial_execution.json').read_text())
a=np.zeros((320,256,4),dtype=np.uint8);poses=[]
for row in data['frames']:
    m=row['ram'];p=m[0x61]
    if m[0x60]:
        b=np.array(Image.open(root/f'research/evidence/animation/decoded_player/{p:03}.png'))
        for x,y,t in d[str(p)]['tiles']:a[y*8:y*8+8,x*8:x*8+8]=b[y*8:y*8+8,x*8:x*8+8]
    Image.fromarray(a[128:192,80:136]).save(out/f"rom/{row['frame']}.png")
    assert (out/f"godot/{row['frame']}.png").exists()
    poses.append(p)
page="""<!doctype html><meta charset="utf-8"><title>Referee partial command</title>
<style>body{background:#10202b;color:#f5efde;font:16px system-ui;margin:25px}img{height:540px;object-fit:contain}#rom{image-rendering:pixelated;width:280px;background:#203040}button,input{margin:10px}section{display:flex;gap:25px}</style>
<h1>Referee 165 / 172: isolated ROM routine vs Godot</h1>
<p>Original bank-11 interpreter executed from $9E13 for 70 ticks. This is an isolated routine test, not a natural-input fight. Source partial tile writes retain the existing body. Original cartoon art and its registration are authored.</p>
<button onclick="play=!play">Play / pause</button><input id="seek" type="range" min="0" max="69" value="0"><span id="label"></span>
<section><div>Decoded ROM tile writes<br><img id="rom"></div><div>Godot original referee<br><img id="godot"></div></section>
<script>const poses=POSES;let f=0,play=false;function show(){document.querySelector('#rom').src='rom/'+f+'.png';document.querySelector('#godot').src='godot/'+f+'.png';document.querySelector('#seek').value=f;document.querySelector('#label').textContent='Tick '+f+' — source command '+poses[f]}document.querySelector('#seek').oninput=e=>{play=false;f=+e.target.value;show()};setInterval(()=>{if(play){f=(f+1)%70;show()}},1000/60);show();</script>"""
(out/'index.html').write_text(page.replace('POSES',json.dumps(poses)),encoding='utf-8')
print('Referee comparison: 70 ROM-executed/Godot pairs')
