"""Compare decoded silhouettes numerically; no production image processing."""
from pathlib import Path
import json
import numpy as np
from PIL import Image
root=Path(__file__).resolve().parents[2]
decoded=json.loads((root/'research/evidence/animation/player_compositor.json').read_text())
poses=[43,44,45,46,47,48,49,50,51,52,53,59,85,86,87,89,90,91,92]
pixels={}
for p in poses:
    x,y,w,h=decoded[str(p)]['box']
    pixels[p]=np.array(Image.open(root/f'research/evidence/animation/decoded_player/{p:03}.png'))[y:y+h,x:x+w]
for p in poses:
    print(p,[(q,'same' if np.array_equal(pixels[p],pixels[q]) else 'mirror') for q in poses if q<p and (np.array_equal(pixels[p],pixels[q]) or np.array_equal(pixels[p],pixels[q][:,::-1]))])
