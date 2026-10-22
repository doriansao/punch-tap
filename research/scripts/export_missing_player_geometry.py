"""Fill unobserved player poses from decoded ROM column streams, not guesses."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[2]
research=root/'research/evidence/animation'
data=json.loads((root/'assets/data/animation_geometry.json').read_text())
decoded=json.loads((research/'player_compositor.json').read_text())
mapping=json.loads((root/'assets/data/pose_art_map.json').read_text())
added=[]
for pose in range(98):
    key=str(pose)
    if key in data['player'] or pose in [58,64,65,66,67]:continue
    box=decoded[key]['box']
    if not box:continue
    x,y,w,h=box;full=list(box)
    evidence='Decoded complete ROM column stream; not an observed PPU call.'
    if pose in [55,56,57]:
        family=decoded['54']['box']
        prefix=np.array(Image.open(research/'decoded_player'/f'{pose:03}.png'))[:,:,3]>0
        template=np.array(Image.open(research/'decoded_player'/'054.png'))[:,:,3]>0
        fx,fy,fw,fh=family
        assert np.array_equal(prefix[y:y+h,x:x+w],template[fy:fy+h,fx:fx+fw])
        full=[x,y,fw,fh];evidence='Exact decoded prefix of ROM pose 54.'
    pixels=np.array(Image.open(research/'decoded_player'/f'{pose:03}.png'))
    glove=(pixels[:,:,1]>200)&(pixels[:,:,3]>0)
    gy,gx=np.where(glove);top=int(gy.min()) if len(gy) else 0
    tip=[float(gx[gy<=top+1].mean()),top] if len(gy) else []
    data['player'][key]={'box':box,'draw_box':full,'world_box':full,'crop_y':[0,h/full[3]],'tip':tip,'display_pose':pose,'art_frame':mapping['player'][key],'art_flip':pose in mapping['player_flip'],'extent_evidence':evidence,'effects':[]}
    added.append(pose)
(root/'assets/data/animation_geometry.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
print('Decoded missing geometry:',added)
