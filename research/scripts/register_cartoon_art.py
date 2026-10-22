"""Read alpha and register atlas regions. Never rewrites image pixels."""
from pathlib import Path
import ast
import json
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
# Reuse the component detector without running the legacy registration exporter.
tree = ast.parse((ROOT/'research/scripts/register_recovered_art.py').read_text())
exec(compile(ast.Module(body=[n for n in tree.body if isinstance(n, ast.FunctionDef)], type_ignores=[]), '<components>', 'exec'))
out = {}
for role, names in {
    'player': ['teo_motion', 'teo_attacks_v2', 'teo_stances', 'teo_finish'],
    'opponent': ['nico_motion', 'nico_reactions', 'nico_stances', 'nico_finish'],
}.items():
    frames = []
    for name in names:
        path = ROOT/'assets/cartoon/production'/f'{name}.png'
        a = np.array(Image.open(path).convert('RGBA'))
        boxes = components(a[:, :, 3] > 24)[:8]
        ordered = {}
        for x, y, r, b, area in boxes:
            col = min(3, int((x+r)/2/(a.shape[1]/4)))
            row = min(1, int((y+b)/2/(a.shape[0]/2)))
            key = row*4+col
            assert key not in ordered, (name, key)
            pix = a[y:b, x:r].astype(int)
            red, green, blue, alpha = (pix[:, :, i] for i in range(4))
            glove = ((green > red+12) & (blue > red+5) & (green > 90)) if role == 'player' else ((red > green*1.7) & (red > blue*1.3) & (red > 130))
            gy, gx = np.where(glove & (alpha > 128))
            top = int(gy.min()) if len(gy) else 0
            tip = [float(np.mean(gx[gy <= top+2])), top] if len(gy) else []
            ordered[key] = dict(texture=f'res://assets/cartoon/production/{name}.png', region=[x,y,r-x,b-y], tip=tip, alpha_component_area=area)
        assert len(ordered) == 8, (name, ordered.keys())
        frames.extend(ordered[i] for i in range(8))
        print(name, '8 isolated regions')
    # Slots 0..7 are legacy aliases, not selected by current recovered pose IDs.
    out[role] = frames[16:24] + frames
    # Image generator reversed these prescribed poses; metadata corrects direction.
    if role == 'opponent':
        for i in [11, 20, 37]: out[role][i]['flip_correction'] = True
    else:
        # Artwork handedness must be combined with recovered row flips.
        # Dodge art 10/11 leaned inward; source poses 96/97 lean away.
        # Punch corrections distinguish the striking hand.
        for i in [10,11,17,19,20]:out[role][i]['flip_correction']=True
# Coherent rising/extended drawings; mirrored hands retain source pose timing.
for name,indices in [('teo_rising_punch_v1',[17,20]),('teo_extended_punch_v1',[21,22]),('teo_special_turn_v1',[13])]:
 path=ROOT/'assets/cartoon/production'/f'{name}.png'
 a=np.array(Image.open(path).convert('RGBA'))
 x,y,r,b,area=components(a[:,:,3]>24)[0]
 pix=a[y:b,x:r].astype(int)
 red,green,blue,alpha=(pix[:,:,j] for j in range(4))
 gy,gx=np.where((green>red+12)&(blue>red+5)&(green>90)&(alpha>128))
 top=int(gy.min());tip=[float(np.mean(gx[gy<=top+2])),top]
 for i in indices:
  out['player'][i]=dict(texture=f'res://assets/cartoon/production/{name}.png',region=[x,y,r-x,b-y],tip=tip,alpha_component_area=area,flip_correction=i in [17,20])
# Source 85/86 are identical raised-arm bodies at different heights; 87 extends.
path=ROOT/'assets/cartoon/production/teo_victory_v2.png'
a=np.array(Image.open(path).convert('RGBA'))
victory=sorted(components(a[:,:,3]>24)[:2],key=lambda b:b[0])
for i,slot in enumerate([32,34]):
 x,y,r,b,area=victory[i]
 out['player'][slot]=dict(texture='res://assets/cartoon/production/teo_victory_v2.png',region=[x,y,r-x,b-y],tip=[],alpha_component_area=area)
out['player'][33]=out['player'][32].copy()
# Consistent right-facing recoil/fall family; source row flips select the left.
path=ROOT/'assets/cartoon/production/teo_recoil_fall_v1.png'
a=np.array(Image.open(path).convert('RGBA'))
recoil=sorted(components(a[:,:,3]>24)[:3],key=lambda b:b[0])
for i,slot in enumerate([35,14,15]):
 x,y,r,b,area=recoil[i]
 out['player'][slot]=dict(texture='res://assets/cartoon/production/teo_recoil_fall_v1.png',region=[x,y,r-x,b-y],tip=[],alpha_component_area=area)
# Source visual 13 is the jab extension, not a taunt. Single-pose replacement.
contact_path=ROOT/'assets/cartoon/production/nico_jab_contact_v3.png'
if contact_path.exists():
    a=np.array(Image.open(contact_path).convert('RGBA'))
    x,y,r,b,area=components(a[:,:,3]>24)[0]
    out['opponent'][9]=dict(texture='res://assets/cartoon/production/nico_jab_contact_v3.png',region=[x,y,r-x,b-y],tip=[],alpha_component_area=area)
# Source visual 12: coiled shoulder windup, same source duration and motion.
windup_path=ROOT/'assets/cartoon/production/nico_jab_windup_v1.png'
if windup_path.exists():
    a=np.array(Image.open(windup_path).convert('RGBA'))
    x,y,r,b,area=components(a[:,:,3]>24)[0]
    out['opponent'][8]=dict(texture='res://assets/cartoon/production/nico_jab_windup_v1.png',region=[x,y,r-x,b-y],tip=[],alpha_component_area=area)
# Dedicated low guard; do not replace shared idle art 25.
body_path=ROOT/'assets/cartoon/production/nico_body_block_v1.png'
if body_path.exists():
    a=np.array(Image.open(body_path).convert('RGBA'))
    x,y,r,b,area=components(a[:,:,3]>24)[0]
    out['opponent'].append(dict(texture='res://assets/cartoon/production/nico_body_block_v1.png',region=[x,y,r-x,b-y],tip=[],alpha_component_area=area))
# Source visual 25: narrow feet. Visual 26 retains the wide stance.
path=ROOT/'assets/cartoon/production/nico_guard_close_v1.png'
a=np.array(Image.open(path).convert('RGBA'))
x,y,r,b,area=components(a[:,:,3]>24)[0]
out['opponent'].append(dict(texture='res://assets/cartoon/production/nico_guard_close_v1.png',region=[x,y,r-x,b-y],tip=[],alpha_component_area=area))
(ROOT/'assets/data/art_registration.json').write_text(json.dumps(out, indent=2)+'\n')

# Draw geometry isolation is part of registration, not bitmap rewriting.
import runpy
runpy.run_path(str(ROOT/"research/scripts/isolate_atlas_geometry.py"),run_name="__main__")
