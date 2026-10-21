from pathlib import Path
import itertools
for name in ['idle','left_head','dodge_left','dodge_right','down']:
 p=Path('research/evidence/'+name+'_ram.bin')
 if not p.exists():continue
 b=p.read_bytes();n=len(b)//2048
 print(name,n)
 for a in [0x50,0x51,0x52,0x54,0x55,0x56,0x57,0x58,0x59,0x5a,0x60,0x70,0x90]:
  vals=[b[i*2048+a] for i in range(n)]
  runs=[(k,len(list(g))) for k,g in itertools.groupby(vals)]
  if len(runs)>1: print(hex(a),runs[:18])
