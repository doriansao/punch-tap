"""Independent screen-pixel check of displayed player poses and scroll positions.

Bright-green source pixels are compared with decoded CHR index 1. Palette
flashes and sprite occlusion can differ; report these rather than call parity.
No bitmap is modified and no source image enters production assets.
"""
from pathlib import Path
from collections import Counter
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[2]
out=root/'research/evidence/motion_audit'
descriptors=json.loads((root/'research/evidence/animation/player_compositor.json').read_text())
decoded={};silhouettes={}
for path in (root/'research/evidence/animation/decoded_player').glob('[0-9][0-9][0-9].png'):
    p=int(path.stem)
    if p>=98:continue
    a=np.array(Image.open(path));decoded[p]=(a[:240,:,0]==220)&(a[:240,:,3]>0)
    silhouettes[p]=a[:240,:,3]>0
counts=Counter();examples=[]
for fixture in ['full','defense','getup','body_counter','getup_finish','round2']:
    rows=json.loads((out/f'frames_{fixture}.json').read_text())
    selected={int(r['frame']) for r in rows}
    trace=json.loads((out/f'trace_{fixture}.json').read_text())
    canvas=np.zeros((240,256),dtype=bool);alpha_canvas=canvas.copy();last_pose=-1
    for row in trace:
        if float(row.get('round_fade',0))>0:
            counts['global_fade_excluded']+=1;continue
        p=row['player'];pose=int(p.get('display_pose',-1))
        # Empty initial presentation is a queue sentinel, not a PPU text write.
        if pose in decoded and pose!=last_pose and p.get('box'):
            # Column streams overwrite whole tiles, retaining untouched tiles.
            # E.g. pose 87 inherits its boots; standalone PNG masks omit them.
            for tx,ty,_ in descriptors[str(pose)]['tiles']:
                if ty>=30:continue
                x=(tx*8)%256;y=ty*8
                canvas[y:y+8,x:x+8]=decoded[pose][y:y+8,x:x+8]
                alpha_canvas[y:y+8,x:x+8]=silhouettes[pose][y:y+8,x:x+8]
            last_pose=pose
        if int(row['frame']) not in selected:continue
        if not p.get('box') or pose not in decoded:counts['invisible']+=1;continue
        expected=np.roll(canvas,-int(p['scroll']),axis=1)
        image=np.array(Image.open(out/fixture/'rom'/f"{int(row['frame'])}.png").convert('RGB'))
        ys,xs=np.where(expected)
        if not len(xs):counts['no_green_landmark']+=1;continue
        left=max(0,int(xs.min())-3);right=min(256,int(xs.max())+4)
        top=max(90,int(ys.min())-3);bottom=min(240,int(ys.max())+4)
        roi=image[top:bottom,left:right]
        # The source changes glove/trunk palette during counts and flashes.
        # Compare the complete spatial mask for each visible palette colour.
        colors=np.unique(roi.reshape(-1,3),axis=0)
        masks=[np.all(roi==color,axis=2) for color in colors]
        diff=min(int(np.count_nonzero(expected[top:bottom,left:right]!=mask)) for mask in masks)
        counts['compared']+=1
        counts['exact' if diff==0 else 'different']+=1
        shifted=np.roll(expected,1,axis=1)
        shifted_diff=min(int(np.count_nonzero(shifted[top:bottom,left:right]!=mask)) for mask in masks)
        counts['plus_one_exact' if shifted_diff==0 else 'plus_one_different']+=1
        visible=np.ones((bottom-top,right-left),dtype=bool)
        for actor in ['opponent','referee']:
            b=row.get(actor,{}).get('box',[])
            if b:
                x,y,w,h=map(int,b)
                visible[max(0,y-top):max(0,min(bottom,y+h)-top),max(0,x-left):max(0,min(right,x+w)-left)]=False
        silhouette=np.roll(alpha_canvas,-int(p['scroll']),axis=1)[top:bottom,left:right]
        foreground=np.any(roi!=image[200,16],axis=2)
        alpha_diff=int(np.count_nonzero((silhouette!=foreground)&visible))
        if np.count_nonzero(silhouette&visible)<10:counts['silhouette_occluded']+=1
        else:counts['silhouette_exact' if alpha_diff==0 else 'silhouette_different']+=1
        visible_expected=expected[top:bottom,left:right]&visible
        if visible_expected.any():
            masked_diff=min(int(np.count_nonzero((expected[top:bottom,left:right]!=mask)&visible)) for mask in masks)
            counts['unoccluded_landmark_exact' if masked_diff==0 else 'unoccluded_landmark_different']+=1
        if diff and len(examples)<24:examples.append({'fixture':fixture,'frame':row['frame'],'pose':pose,'different_pixels':diff})
report={'scope':'Actual ROM screen pixels versus stateful decoded column writes, displayed pose and scroll. Palette changes are matched by complete colour masks. Opponent/referee rectangles exclude occlusion for silhouette checks. This validates source presentation timing/placement, not original-art anatomy or every game path.', 'counts':dict(counts),'examples':examples}
(out/'displayed_pixels.json').write_text(json.dumps(report,indent=2))
print(report)
assert not counts['silhouette_different'] and not counts['unoccluded_landmark_different'], 'Unexplained displayed pose/position differences'
