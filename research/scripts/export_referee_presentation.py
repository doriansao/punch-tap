"""Export numeric referee descriptors; never copy CHR/tile artwork to assets.

Run decode_player_compositor.py first. Bank-11 $8280 selects these background
updates through the same live interpreter as the player. Speech updates retain
the existing body. Original-art pose assignments are authored, not ROM art.
"""
from pathlib import Path
import json

root = Path(__file__).resolve().parents[2]
decoded = json.loads((root/'research/evidence/animation/player_compositor.json').read_text())
commands = {'128': {'clear': True}}
for pose in list(range(129,153))+[164,165,173]:
    art = (1 if pose % 2 else 2) if pose <= 149 else 0
    if pose == 164: art = 6
    if pose == 165: art = 7
    if pose == 173: art = 4
    commands[str(pose)] = {'world_box': decoded[str(pose)]['box'], 'art': art}
# $9D78/$9E17 issue 172 after 165. Compose whole tile writes, retaining
# untouched head/torso/feet; the standalone partial box is not a body box.
from PIL import Image
import numpy as np
pixels=np.array(Image.open(root/'research/evidence/animation/decoded_player/165.png'))
partial=np.array(Image.open(root/'research/evidence/animation/decoded_player/172.png'))
for x,y,_ in decoded['172']['tiles']:
    pixels[y*8:y*8+8,x*8:x*8+8]=partial[y*8:y*8+8,x*8:x*8+8]
y,x=np.where(pixels[:,:,3]>0)
commands['172']={'world_box':[int(x.min()),int(y.min()),int(x.max()-x.min()+1),int(y.max()-y.min()+1)],'art':8,'draw_world_x':105.5,'requires_previous':[165,172]}
for pose in ['164','165']:commands[pose]['draw_world_x']=105.5
data = {'scope': 'Source-derived complete body updates and clear 128; speech/attribute updates preserve the body. Partial 172 is composed after its reachable predecessor 165. Art registration is authored.', 'commands': commands}
(root/'assets/data/referee_presentation.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
print('Exported',len(commands),'numeric referee commands')
