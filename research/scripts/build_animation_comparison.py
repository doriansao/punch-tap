from pathlib import Path
import json,html
ROOT=Path(__file__).resolve().parents[1]
folder=ROOT/'evidence/comparison'
data=json.loads((folder/'index.json').read_text())
registration=json.loads((ROOT.parent/'assets/data/art_registration.json').read_text())
for clip,item in data.items():
 for age,row in enumerate(item['frames']):
  assert (folder/clip/f'{age:04}.png').exists()
  for role in ['player','opponent']:
   r=row[role]
   if not r['box'] or not r['tip']:continue
   art=registration[role][r['art_pose']]
   if not art['tip']:continue
   x,y,w,h=r.get('draw_box',r['box']);ax,ay=art['tip'];_,_,aw,ah=art['region']
   # Production renderer preserves aspect ratio and centers each registered alpha body.
   scale=h/ah
   u=aw-ax if r.get('art_flip',False) else ax
   predicted=[x+w/2+(u-aw/2)*scale,y+ay*scale]
   r['art_glove_marker']=predicted
   r['glove_marker_error_nes_pixels']=round(sum((predicted[i]-r['tip'][i])**2 for i in range(2))**.5,2)
(folder/'registration_errors.json').write_text(json.dumps({clip:[{'frame':r['frame'],'player_tip_error':r['player'].get('glove_marker_error_nes_pixels'),'opponent_tip_error':r['opponent'].get('glove_marker_error_nes_pixels')}for r in item['frames']]for clip,item in data.items()},indent=2))
page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>Punch Tap — ROM / Godot comparison</title>
<style>body{margin:24px;background:#101c2c;color:#f6ebd5;font:16px system-ui}h1{font-size:24px}p{max-width:1100px}.warning{padding:14px;border-left:5px solid #ff715d;background:#273344}select,button,input{font:inherit;margin:5px;padding:7px}input{width:50vw}.views{display:flex;gap:20px;align-items:flex-start;flex-wrap:wrap}.views img{max-width:100%;object-fit:contain;border:1px solid #547978}.rom{width:512px;image-rendering:pixelated}.godot{width:405px}pre{white-space:pre-wrap;max-width:1150px;font-size:13px}label{display:inline-block}</style>
<h1>Punch Tap — measured ROM animation / original-art mapping</h1>
<p class="warning"><b>Scope:</b> the Godot panel replays the selected measured animation clip through the production renderer. It is NOT an independently played, frame-matched full bout. The expanded original-art atlas uses explicit recovered pose mappings and registered alpha bounds. Glove-marker errors below measure the remaining difference between the new anatomy and the ROM reach marker. Yellow crosses show ROM reach markers, not verified hitboxes.</p>
<label>Sequence <select id="clip"></select></label><button id="prev">◀ Frame</button><button id="play">Play at 60 Hz</button><button id="next">Frame ▶</button>
<label>ROM layer <select id="layer"><option value="full">Full composition</option><option value="player">Player only</option><option value="opponent">Opponent only</option></select></label>
<div><input id="seek" type="range" value="0"><b id="position"></b></div>
<div class="views"><div><h2>Actual ROM screenshot</h2><img id="rom" class="rom"></div><div><h2>Godot renderer / original art</h2><img id="godot" class="godot"></div></div>
<pre id="info"></pre><p>Player box is the visible silhouette inside the fight-area background crop. Opponent box is the visible sprite silhouette within the fighter-anchor window, excluding the distant referee. Pixel bounds are research measurements, not decoded collision geometry. The body proportions of the current art do not match every source pose.</p>
<script>const data=DATA;const clip=document.getElementById('clip'),seek=document.getElementById('seek'),layer=document.getElementById('layer');for(const key of Object.keys(data)){const option=document.createElement('option');option.value=key;option.textContent=key;clip.append(option)}let playing=false,last=0,acc=0;function show(){const t=data[clip.value],i=+seek.value,r=t.frames[i];seek.max=t.frames.length-1;document.getElementById('rom').src='../animation/'+t.case+'/'+layer.value+'/'+r.frame+'.png';document.getElementById('godot').src=clip.value+'/'+String(i).padStart(4,'0')+'.png';document.getElementById('position').textContent='age '+i+' / '+(t.frames.length-1)+' — ROM frame '+r.frame;document.getElementById('info').textContent=JSON.stringify({case:t.case,age:i,frame:r.frame,player:r.player,opponent:r.opponent},null,2)}clip.onchange=()=>{seek.value=0;show()};layer.onchange=show;seek.oninput=show;function step(d){seek.value=Math.max(0,Math.min(data[clip.value].frames.length-1,+seek.value+d));show()}document.getElementById('prev').onclick=()=>step(-1);document.getElementById('next').onclick=()=>step(1);document.getElementById('play').onclick=()=>{playing=!playing;document.getElementById('play').textContent=playing?'Pause':'Play at 60 Hz'};document.onkeydown=e=>{if(e.key==='ArrowLeft')step(-1);if(e.key==='ArrowRight')step(1)};function loop(time){if(playing){acc+=time-last;const n=Math.floor(acc/(1000/60));if(n){acc-=n*(1000/60);seek.value=(+seek.value+n)%data[clip.value].frames.length;show()}}else acc=0;last=time;requestAnimationFrame(loop)}show();requestAnimationFrame(loop);</script></html>'''
(folder/'index.html').write_text(page.replace('DATA',json.dumps(data)),encoding='utf-8')
print('Built comparison:',sum(len(c['frames']) for c in data.values()),'frame pairs across',len(data),'clips')
