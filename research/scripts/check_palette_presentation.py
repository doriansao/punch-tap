"""Check queued palette cues against source RAM and the state-22 screen pulse."""
from pathlib import Path
import json, struct
from PIL import Image
root=Path(__file__).resolve().parents[2]
base=root/'research/evidence/motion_audit'
checked=pulses=0
for fixture in ['full','defense','getup','body_counter']:
    raw=(root/f'research/evidence/animation/coupled_{fixture}_fight.bin').read_bytes()
    expected={}
    for off in range(0,len(raw),4110):
        ram=raw[off+2062:off+4110]
        expected[struct.unpack_from('<I',raw,off)[0]+2]=ram[0x493]==ram[0x5ec] and ram[0x5ec]!=ram[0x5ed]
    for row in json.loads((base/f'frames_{fixture}.json').read_text()):
        f=row['frame']
        if f not in expected:continue
        assert row['opponent']['palette_pulse']==expected[f],(fixture,f)
        checked+=1;pulses+=expected[f]
# Exact measured source skin colour is used only to inspect research captures.
# It is not exported into production art or runtime data.
for f in range(3366,3376):
    screen=Image.open(base/f'body_counter/rom/{f}.png').convert('RGB')
    count=sum(pixel==(254,129,112) for pixel in screen.crop((105,85,160,150)).get_flattened_data())
    assert (count>300)==(3369<=f<=3372),(f,count)
report={'queued_frames':checked,'pulse_frames':pulses,'state22_screen_pulse':[3369,3372],
        'scope':'Source palette routine and two-frame display queue; original coral tint is authored.'}
(base/'palette_validation.json').write_text(json.dumps(report,indent=2))
print(report)
