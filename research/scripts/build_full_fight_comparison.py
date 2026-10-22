"""Build an ignored local viewer from independently simulated full-fight captures."""
from pathlib import Path
import json,sys
sequence='--sequence' in sys.argv
defense='--defense' in sys.argv
getup='--getup' in sys.argv
body='--body' in sys.argv
contacts='--contacts' in sys.argv or body
root=Path('research/evidence/getup_audit' if getup else ('research/evidence/body_audit' if body else ('research/evidence/contact_audit' if contacts else 'research/evidence/full_fight')))
if defense:root=Path('research/evidence/defense_audit')
if sequence:root=Path('research/evidence/sequence_audit')
rows=json.loads((root/'frames.json').read_text(encoding='utf-8'))
report=json.loads(Path('research/evidence/animation/getup_fight_validation.json' if getup else ('research/evidence/animation/body_fight_validation.json' if body else 'research/evidence/animation/full_fight_validation.json')).read_text(encoding='utf-8'))
if defense:report=json.loads(Path('research/evidence/animation/defense_fight_validation.json').read_text(encoding='utf-8'))
assert len(rows)==(121 if sequence else 326 if defense else 226 if getup else 36 if body else 63 if contacts else 621), 'Incomplete visual capture'
for row in rows:
 for side in ['rom','godot']:assert (root/side/f"{row['frame']}.png").exists()
page='''<!doctype html><html lang="en"><meta charset="utf-8"><title>Punch Tap — full fight comparison</title>
<style>body{margin:24px;background:#101c2c;color:#f6ebd5;font:16px system-ui}h1{font-size:24px}p{max-width:1100px}.scope{border-left:4px solid #70f0c0;padding:12px;background:#1b3040}button,select{padding:8px;background:#244657;color:inherit;border:1px solid #70f0c0;border-radius:6px;margin:4px}input{width:min(800px,85vw)}.views{display:flex;gap:24px;align-items:flex-start;flex-wrap:wrap}.rom{width:512px;image-rendering:pixelated}.godot{width:405px}img{max-width:100%}pre{white-space:pre-wrap;font-size:13px}small{color:#a6c2c7}</style>
<h1>One full fight · ROM vs playable Godot adapter</h1>
<p class="scope"><b>4,959 consecutive frames · 48 contacts · 3 knockdowns · TKO.</b> All 143 checked gameplay and animation fields match. Godot starts from one captured initial state and receives stable raw controller samples; its own polling, AI, animation and combat code run continuously. No animation-track overrides or per-frame combat-state injection.</p>
<p>The images sample every eight frames (plus the final frame); the numerical test checks every frame. This proves this first-round strategy, not every possible fight. Entrance, inter-round screens, hardware serial sampling and full PPU parity are outside scope. Replacement anatomy and floor registration are authored.</p>
<button id="play">Play</button><button id="prev">Previous</button><button id="next">Next</button><select id="events"><option value="">Jump to contact / knockdown</option></select>
<div><input type="range" id="seek" min="0" value="0"><b id="label"></b></div>
<div class="views"><div><h2>ROM capture</h2><img class="rom" id="rom"></div><div><h2>Godot live simulation</h2><img class="godot" id="godot"></div></div>
<pre id="info"></pre><small>Local research only. ROM screenshots are excluded from the public repository.</small>
<script>const rows=ROWS,report=REPORT;let i=0,playing=false,last=0;const seek=document.getElementById('seek'),ev=document.getElementById('events');seek.max=rows.length-1;for(const e of report.runs[0].events){const o=document.createElement('option');o.value=e.frame;o.textContent=e.frame+' · '+e.kind+' · '+e.detail;ev.append(o)}function show(){const r=rows[i];seek.value=i;document.getElementById('rom').src='rom/'+r.frame+'.png';document.getElementById('godot').src='godot/'+r.frame+'.png';document.getElementById('label').textContent='ROM frame '+r.frame+' · '+((r.frame-2018)/60).toFixed(2)+' s';document.getElementById('info').textContent=JSON.stringify({frame:r.frame,buttons:r.buttons,hp:r.hp,opponent_hp:r.opponent_hp,phase:r.phase,downs:r.downs,player_pose:r.player.display_pose,opponent_body:r.opponent.composition,opponent_art:r.opponent.art_frame,referee:r.referee},null,2)}function move(d){i=Math.max(0,Math.min(rows.length-1,i+d));show()}seek.oninput=()=>{i=+seek.value;show()};ev.onchange=()=>{let best=0;for(let n=0;n<rows.length;n++)if(Math.abs(rows[n].frame-ev.value)<Math.abs(rows[best].frame-ev.value))best=n;i=best;show()};document.getElementById('prev').onclick=()=>move(-1);document.getElementById('next').onclick=()=>move(1);document.getElementById('play').onclick=()=>{playing=!playing;document.getElementById('play').textContent=playing?'Pause':'Play';last=0};function loop(t){if(playing){if(!last)last=t;const step=1000*8/60;if(t-last>=step){const n=Math.floor((t-last)/step);i=(i+n)%rows.length;show();last+=n*step}}requestAnimationFrame(loop)}show();requestAnimationFrame(loop);</script></html>'''
if sequence:
 page=page.replace('One full fight · ROM vs playable Godot adapter','Every-frame animation · ROM vs Godot')
 page=page.replace('The images sample every eight frames (plus the final frame); the numerical test checks every frame.', 'Every frame from 2290 through 2410 is present: 121 pairs at 60 source frames/second. Both head punches and recovery are shown without frame skipping. Updated rising/extended art and handedness registration remove the mid-punch hand swap; original timing and reach remain unchanged. Art registration is authored. The separate pose-25 guard change is exercised in presentation/guard_25.png, not this window. This is not proof all animation gaps are fixed.')
 page=page.replace('1000*8/60','1000/60')
 frames={row['frame'] for row in rows}
 report['runs'][0]['events']=[e for e in report['runs'][0]['events'] if e['frame'] in frames]
if contacts:
 page=page.replace('One full fight · ROM vs playable Godot adapter','Contact audit · seven nine-frame windows')
 page=page.replace('The images sample every eight frames (plus the final frame); the numerical test checks every frame.', 'These 63 image pairs show every frame from three frames before through five after seven contacts. They cover both head-punch hands, moving counters, knockdown initiation, a head block and an incoming jab. Body punches and other strategies remain unverified.')
 page=page.replace('1000*8/60','1000/60')
 frames={row['frame'] for row in rows}
 report['runs'][0]['events']=[e for e in report['runs'][0]['events'] if e['frame'] in frames]
if body:
 page=page.replace('Contact audit · seven nine-frame windows','Body block audit · four nine-frame windows')
 page=page.replace('4,959 consecutive frames · 48 contacts · 3 knockdowns · TKO.','3,135 consecutive frames · 29 contacts · player count-ten KO.')
 page=page.replace('These 63 image pairs show every frame from three frames before through five after seven contacts. They cover both head-punch hands, moving counters, knockdown initiation, a head block and an incoming jab. Body punches and other strategies remain unverified.', 'These 36 image pairs cover four body blocks. The strategy exhausts hearts and ends in player KO. The recovered fatigue flag now survives knockdown; this strategy excludes successful body hits and get-up. The dedicated original low-guard drawing joins both gloves over the belly; other compositions and source timing are unchanged.')
if getup:
 page=page.replace('One full fight · ROM vs playable Godot adapter','Player get-up · source vs Godot')
 page=page.replace('4,959 consecutive frames · 48 contacts · 3 knockdowns · TKO.','3,983 consecutive frames · 44 contacts · two successful get-ups.')
 page=page.replace('The images sample every eight frames (plus the final frame); the numerical test checks every frame.', '226 image pairs sample every eight frames from 4200 through 6000. The numerical test covers all 3983 frames from first control, including two successful returns to combat. The later third knockdown is incomplete; this is not a complete bout. The apron now aligns with source y=240; hidden get-up anatomy remains authored.')
 report['runs'][0]['events']=[e for e in report['runs'][0]['events'] if e['frame']>=4200]
if defense:
 page=page.replace('One full fight · ROM vs playable Godot adapter','Defense and anticipation · source vs Godot')
 page=page.replace('4,959 consecutive frames · 48 contacts · 3 knockdowns · TKO.','2,183 consecutive frames · two guards · four successful slips.')
 page=page.replace('The images sample every eight frames (plus the final frame); the numerical test checks every frame.', '326 pairs sample every four frames from 2900 through 4200. Six natural jabs exercise guard, left slip and right slip. All checked gameplay fields match. Dodge art 10/11 now leans outward, matching source pose intent. Narrower authored jab v3 reveals the right-slip head at frames 3360/4056 while retaining central hit/guard contact. Right silhouette edges remain close; numerical parity does not establish complete visual parity. Body-cross state 22 was not observed. Authored warning audio now starts with displayed windup.')
 page=page.replace('1000*8/60','1000*4/60')
(root/'index.html').write_text(page.replace('ROWS',json.dumps(rows)).replace('REPORT',json.dumps(report)),encoding='utf-8')
print(f'Full-fight comparison: {len(rows)} paired previews; {report["runs"][0]["frames"]} checked frames')
