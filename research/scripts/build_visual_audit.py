"""Build a local, frame-steppable ROM evidence viewer; no image manipulation."""
from pathlib import Path
import csv, json, hashlib
root=Path(__file__).resolve().parents[1]/'evidence/visual_audit'
rows=list(csv.DictReader((root/'frames.csv').open()))
assert len(rows)==1106 and rows[0]['frame']=='2295' and rows[-1]['frame']=='3400'
for row in rows:
 p=root/(row['frame']+'.png')
 assert p.exists(), p
 row['screenshot_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
(root/'manifest.json').write_text(json.dumps(rows,indent=2))
html='''<!doctype html><meta charset="utf-8"><title>Punch Tap ROM animation evidence</title>
<style>body{background:#101c2c;color:#f6ebd5;font:18px system-ui;max-width:1000px;margin:30px auto}img{width:512px;image-rendering:pixelated}button,input{font:inherit;margin:6px}pre{white-space:pre-wrap;font-size:14px}section{display:flex;gap:24px}input{width:650px}</style>
<h1>ROM animation evidence — cold boot, ordinary input</h1>
<p>These are ROM screenshots for local research, not production art. Step through actual frames and script state. No frame-perfect Godot equivalence is claimed.</p>
<button id="prev">Previous</button><button id="next">Next</button><input id="seek" type="range" min="0" max="1105" value="5">
<section><img id="shot"><pre id="info"></pre></section>
<p>Inputs: frame 2300 left body; 2400 right body; 2500 left head; 2600 right head; 2700 left dodge; 2800 right dodge; 2990–3029 held guard. Short pulses last three frames. State is sampled at endFrame; input polling and rendering can introduce offsets.</p>
<p>Player $50 state, $52 timer, $53 cursor, $54/$55 pointer; opponent $90 state, $92 timer, $93 cursor, $94/$95 pointer; $A5 sprite-sequence cursor. Cursors are not global pose IDs. Recover branch/pose meanings before mapping original artwork.</p>
<script>const rows=ROWS;const seek=document.getElementById('seek');function show(){const r=rows[+seek.value];document.getElementById('shot').src=r.frame+'.png';document.getElementById('info').textContent=JSON.stringify(r,null,2)}seek.oninput=show;document.getElementById('prev').onclick=()=>{seek.value=Math.max(0,+seek.value-1);show()};document.getElementById('next').onclick=()=>{seek.value=Math.min(1105,+seek.value+1);show()};document.onkeydown=e=>{if(e.key==='ArrowRight')document.getElementById('next').click();if(e.key==='ArrowLeft')document.getElementById('prev').click()};show();</script>'''
(root/'index.html').write_text(html.replace('ROWS',json.dumps(rows)),encoding='utf-8')
print('Verified 1106 screenshots; built manifest and frame-step viewer')
