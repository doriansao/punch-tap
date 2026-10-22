"""Decode HUD control/RNG commands, excluding original text and graphics."""
from pathlib import Path
import json
root=Path(__file__).resolve().parents[2]
r=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16+7*8192:16+8*8192]
commands={};todo=[(0x8cd8,0x8cd8),(0x8d1a,0x8d1a)]
while todo:
 pc,base=todo.pop()
 if str(pc) in commands:continue
 byte=r[pc-0x8000];op=byte>>5;param=byte&31
 assert op in [0,2,3,4,6,7],(hex(pc),byte)
 size=2 if op in [0,4] else 1
 commands[str(pc)]={'op':['branch','','choose','choose_alt','wait','','draw','draw_alt'][op],'value':param&15,'next':pc+size}
 if size==2:commands[str(pc)]['operand']=r[pc-0x8000+1]
 if op==0:
  todo.append((base+r[pc-0x8000+1],base))
  if param&15==15:continue
 todo.append((pc+size,base))
 assert len(commands)<150
(root/'assets/data/presentation_control.json').write_text(json.dumps({'initial':{'1':0x8cd8,'2':0x8d1a},'commands':commands,'scope':'HUD control flow and RNG consumption only; no original text or tile graphics.'},indent=2)+'\n',encoding='utf-8')
print(len(commands),'semantic presentation commands')
