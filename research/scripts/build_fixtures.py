from pathlib import Path
import json,hashlib
root=Path('research/evidence');cases={}
for name in ['left_body','right_body','left_head','right_head','dodge_left','dodge_right','down','hold_left']:
 p=root/(name+'_ram.bin');b=p.read_bytes()
 assert len(b)==306*2048,(name,len(b))
 cases[name]={'sha256':hashlib.sha256(b).hexdigest(),'first_sample_frame':2295,'accepted_sample':7,'state':[b[i+0x50] for i in range(0,len(b),2048)],'contact':[b[i+0x58] for i in range(0,len(b),2048)]}
Path('tests/fixtures/player_actions.json').write_text(json.dumps(cases,indent=2))
