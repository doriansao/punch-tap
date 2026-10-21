from pathlib import Path
import json

data = Path('research/evidence/fight_policy_ram.bin').read_bytes()
rows = []
for i in range(1, len(data)//2048):
    prev, now = data[(i-1)*2048:i*2048], data[i*2048:(i+1)*2048]
    if now[0x398] < prev[0x398]:
        rows.append(dict(frame=2295+i, hp=prev[0x398],
                         knockout_window=bool(prev[0xBA]), ordinary_damage=5,
                         expected=now[0x398]))
Path('tests/fixtures/head_contacts.json').write_text(json.dumps(rows, indent=2))
