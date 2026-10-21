from pathlib import Path
import csv
for name in ['body_stars','normal_knockdowns','player_getup','head_stars']:
 p=Path('research/evidence/'+name+'.csv')
 if not p.exists():continue
 rows=list(csv.DictReader(p.open()));rows=[r for r in rows if r.get('joe_hp')]
 print(name,len(rows),'last',rows[-1] if rows else '')
 for col in ['stars','hp','joe_hp','hearts']:
  print(col,[(r['frame'],r[col]) for i,r in enumerate(rows) if i==0 or r[col]!=rows[i-1][col]][:35])
