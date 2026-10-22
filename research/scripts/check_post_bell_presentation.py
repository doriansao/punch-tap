"""Compare live Godot fade phases with end-frame ROM RAM, not fixture duration."""
from pathlib import Path
import json,struct
from PIL import Image
root=Path(__file__).resolve().parents[2]
raw=(root/'research/evidence/post_bell/frames.bin').read_bytes()
source={}
for off in range(0,len(raw),2052):source[struct.unpack_from('<I',raw,off)[0]]=raw[off+4:off+2052]
rows=json.loads((root/'research/evidence/motion_audit/frames_body_counter.json').read_text())
checked=0;clock_checked=0
for row in rows:
    f=row['frame']
    if 5725<=f<=5858:
        im=Image.open(root/f'research/evidence/motion_audit/body_counter/rom/{f}.png').convert('RGB')
        white=sum(pixel==(255,254,255) for pixel in im.crop((208,24,240,32)).get_flattened_data())
        assert row['clock_visible']==(white>30),(f,row['clock_visible'],white)
        clock_checked+=1
    if not 5858<=f<=5903:continue
    m=source[f]
    assert abs(row['round_fade']-(1-m[0x4c8]/64))<0.001,(f,row['round_fade'],m[0x4c8])
    assert (row['state']=='between_rounds')==(m[4]!=255),(f,row['state'],m[4])
    checked+=1
assert checked==46
report={'frames':checked,'clock_pixel_frames':clock_checked,'scope':'Source palette fade threshold and switch out of active-fight routing; Godot opacity is an authored replacement for NES palette darkening.'}
(root/'research/evidence/post_bell/presentation_validation.json').write_text(json.dumps(report,indent=2))
print(report)
