"""Validate full-rate clip coverage and build a local, preloaded comparison viewer."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[2]
out=root/'research/evidence/motion_audit'
clips=json.loads((root/'research/scripts/motion_audit_clips.json').read_text())
rows=[]
for fixture in dict.fromkeys(c['fixture'] for c in clips):
    rows+=json.loads((out/f'frames_{fixture}.json').read_text())
lookup={(r['fixture'],r['frame']):r for r in rows}
coverage=[]
for c in clips:
    c['rows']=[]
    for frame in range(c['start'],c['end']+1):
        row=lookup[c['fixture'],frame]
        for side in ['rom','godot']:
            assert (out/c['fixture']/side/f'{frame}.png').is_file(),(c,side,frame)
        c['rows'].append(row)
    coverage.append({'name':c['name'],'fixture':c['fixture'],'frames':len(c['rows']),
                     'player_poses':sorted({int(r['player'].get('display_pose',-1)) for r in c['rows']}),
                     'opponent_poses':sorted({int(r['opponent'].get('visual_pose_id',-1)) for r in c['rows']})})
(out/'coverage.json').write_text(json.dumps(coverage,indent=2))
page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>Punch Tap · Motion audit</title>
<style>body{background:#101c2c;color:#f7eddc;font:16px system-ui;margin:24px}h1{font-size:25px}button,select{background:#244657;color:inherit;padding:8px;border:1px solid #70f0c0;border-radius:6px;margin:4px}input{width:70vw}.views{display:flex;gap:24px;align-items:flex-start}.rom{width:512px;image-rendering:pixelated}.godot{width:360px}img{max-width:100%}pre{white-space:pre-wrap;font-size:13px}.scope{max-width:1000px;background:#1b3040;padding:12px}small{color:#a6c2c7}</style>
<h1>Remaining animation families · ROM / Godot</h1>
<p class="scope">Every source frame is included in each clip. Godot runs the live adapter from one initial seed and recorded inputs; no per-frame combat reseeding. Recovered holds, movement and contact frames are preserved. Original drawings, anatomy and registration are authored. This is a visual audit of the listed first-opponent paths, not proof of every possible game path.</p>
<select id="clips"></select><button id="play">Play</button><button id="prev">−1 frame</button><button id="next">+1 frame</button><button id="pose">Next pose</button><select id="speed"><option value="60">60 source fps</option><option value="30">Half speed</option><option value="15">Quarter speed</option></select>
<p id="status"></p><input id="seek" type="range" min="0" value="0"><b id="label"></b>
<div class="views"><div><h2>ROM</h2><img id="rom" class="rom"></div><div><h2>Godot</h2><img id="godot" class="godot"></div></div><pre id="info"></pre>
<small>Local research screenshots remain excluded from production assets and Git.</small>
<script>const clips=DATA;let c=0,i=0,playing=false,last=0,cache=[],generation=0;
const el=id=>document.getElementById(id),sig=r=>JSON.stringify([r.player.display_pose,r.opponent.composition,r.opponent.visual_pose_id]);
clips.forEach((v,n)=>{const o=document.createElement('option');o.value=n;o.textContent=v.name;el('clips').append(o)});
function show(){const r=clips[c].rows[i];el('seek').value=i;el('label').textContent='frame '+r.frame+' · '+(i/60).toFixed(2)+' s';for(const side of ['rom','godot'])el(side).src=clips[c].fixture+'/'+side+'/'+r.frame+'.png';el('info').textContent=JSON.stringify({player_pose:r.player.display_pose,player_art:r.player.art_frame,player_box:r.player.box,opponent_pose:r.opponent.visual_pose_id,opponent_art:r.opponent.art_frame,opponent_box:r.opponent.box,referee:r.referee.speech},null,2)}
async function choose(){const token=++generation;playing=false;el('play').textContent='Play';el('play').disabled=true;c=+el('clips').value;i=0;cache=[];el('seek').max=clips[c].rows.length-1;show();el('status').textContent='Preloading this clip to avoid disk-loading stutter…';let count=0;await Promise.all(clips[c].rows.flatMap(r=>['rom','godot'].map(side=>new Promise(resolve=>{const im=new Image();cache.push(im);im.onload=()=>{count++;resolve()};im.onerror=resolve;im.src=clips[c].fixture+'/'+side+'/'+r.frame+'.png'}))));if(token!==generation)return;el('status').textContent=count+' images ready · '+clips[c].rows.length+' consecutive frames';el('play').disabled=false;}
el('clips').onchange=choose;el('seek').oninput=()=>{i=+el('seek').value;show()};el('prev').onclick=()=>{i=Math.max(0,i-1);show()};el('next').onclick=()=>{i=Math.min(clips[c].rows.length-1,i+1);show()};el('pose').onclick=()=>{const s=sig(clips[c].rows[i]);do{i++}while(i<clips[c].rows.length-1&&sig(clips[c].rows[i])===s);i=Math.min(i,clips[c].rows.length-1);show()};el('play').onclick=()=>{playing=!playing;last=0;el('play').textContent=playing?'Pause':'Play'};
function loop(t){if(playing){if(!last)last=t;const step=1000/+el('speed').value;if(t-last>=step){const n=Math.floor((t-last)/step);i=(i+n)%clips[c].rows.length;last+=n*step;show()}}requestAnimationFrame(loop)}choose();requestAnimationFrame(loop);</script></html>'''
(out/'index.html').write_text(page.replace('DATA',json.dumps(clips,separators=(',',':'))),encoding='utf-8')
print('Motion audit:',len(coverage),'clips,',sum(c['frames'] for c in coverage),'consecutive image pairs')
