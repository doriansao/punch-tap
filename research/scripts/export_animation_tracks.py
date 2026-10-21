"""Export measured animation samples and an explicit art correspondence table."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
d=json.loads((ROOT/'research/evidence/animation/measurements.json').read_text())
def clip(case,start,end):
 rows=d[case]['frames'][start-d[case]['start']:end-d[case]['start']+1]
 assert len(rows)==end-start+1
 return {'case':case,'start':start,'frames':rows}
def first(case,role,state):
 rows=d[case]['frames'];i=next(i for i,r in enumerate(rows) if r[role]['state']==state)
 j=i+1
 while j<len(rows) and rows[j][role]['state']==state:j+=1
 return clip(case,rows[i]['frame'],rows[j-1]['frame'])
clips={name:first('visual_audit','player',state) for name,state in [('left_body',9),('right_body',10),('left_head',11),('right_head',12),('dodge_left',5),('dodge_right',3),('down',7)]}
clips.update(special=first('normal_knockdowns','player',13),idle=clip('idle_long',2295,2797),jab=first('idle_long','opponent',21),cross=first('idle_long','opponent',22),taunt_long=first('idle_long','opponent',25),taunt_short=first('normal_knockdowns','opponent',25),reaction_left=first('normal_knockdowns','opponent',13),reaction_right=first('normal_knockdowns','opponent',14),hurt=clip('idle_long',3008,3047),opponent_down=clip('normal_knockdowns',3413,4124),player_down=clip('player_getup_wide',4084,4518))
clips['opponent_ko']=clip('normal_knockdowns',6296,7022)
# Numeric data only; no screenshot pixels or ROM executable data exported.
for item in clips.values():
 for row in item['frames']:
  for role in ['player','opponent']:
   row[role].pop('mask_hash',None)
(ROOT/'assets/data/animation_tracks.json').write_text(json.dumps(clips,separators=(',',':')))
# Inventory is explicitly separate from source reconstruction. Reuse of a key
# pose is visible, never silently counted as an exact recovered art frame.
inventory={role:sorted({str(r[role]['pose'])for c in clips.values()for r in c['frames']})for role in ['player','opponent']}
(ROOT/'research/evidence/animation/required_pose_inventory.json').write_text(json.dumps(inventory,indent=2))
print('Exported',len(clips),'measured clips;',sum(len(c['frames'])for c in clips.values()),'paired frame samples')
for k,v in clips.items():print(k,v['case'],v['start'],len(v['frames']))
