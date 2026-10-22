"""Numeric first-controllable-frame state, from capture_fight_start.lua."""
from pathlib import Path
import json,struct
root=Path(__file__).resolve().parents[2]
raw=(root/'research/evidence/animation/fight_start_ram.bin').read_bytes()
ram=None
for offset in range(0,len(raw),2052):
    if struct.unpack_from('<I',raw,offset)[0]==2017:
        ram=raw[offset+4:offset+2052];break
assert ram is not None and ram[0x90]==1 and ram[0x50]==1
path=root/'assets/data/animation_geometry.json'
data=json.loads(path.read_text())
data['fight_initial']={key:ram[int(key)] for key in data['initial']}
path.write_text(json.dumps(data,separators=(',',':'))+'\n',encoding='utf-8')
print('Exported first controllable reference frame 2017 (clock 0:01).')
