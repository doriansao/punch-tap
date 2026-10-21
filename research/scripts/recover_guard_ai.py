from pathlib import Path
from py65.devices.mpu6502 import MPU
import json
root=Path('research/evidence/animation');rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088];out=[];fields=[0x18,0x90,0x99,0xab,0xac,0x4fd,0x4fe,0x4ff]
for case in ['visual_audit','normal_knockdowns','player_getup_wide','idle_long','right_knockdowns']:
 raw=(root/case/'full/ram.bin').read_bytes()
 for off in range(0,len(raw),2048):
  b=raw[off:off+2048]
  if b[4]!=255:continue
  m=list(b)+[0]*63488;m[0x8000:0xa000]=rom[:8192];m[0xa000:]=rom[-0x6000:];m[0x1fe]=254;m[0x1ff]=127;cpu=MPU(memory=m);cpu.pc=0xc291;cpu.sp=253
  for _ in range(1000):
   if cpu.pc==0x7fff:break
   cpu.step()
  else:raise RuntimeError('guard AI budget')
  out.append([list(b),[m[a]for a in fields]])
(root/'guard_ai_cases.json').write_text(json.dumps({'fields':fields,'cases':out},separators=(',',':')));print(len(out),'guard AI oracle cases')
