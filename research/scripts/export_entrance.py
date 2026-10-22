"""Export entry RAM using the existing logical-state whitelist; no sprite tiles."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[2]
raw=(root/'research/evidence/animation/normal_knockdowns_entrance_opponent_step.bin').read_bytes()
m=raw[4:2052]
keys=json.loads((root/'assets/data/animation_geometry.json').read_text())['initial']
data={'source_first_frame':1130,'duration':887,'initial':{k:m[int(k)] for k in keys},'gates':[[2,27,1],[804,187,1]],'initial_selector':58,'scope':'Live animation VM; two source-observed entrance gate overrides, ownership unverified.'}
(root/'assets/data/entrance.json').write_text(json.dumps(data,separators=(',',':'))+'\n')
