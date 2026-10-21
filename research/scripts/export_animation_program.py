"""Export animation data as named semantic commands, never executable 6502 code."""
from pathlib import Path
import json,struct
from player_animation_vm import PlayerVM
root=Path(__file__).resolve().parents[2]
m=PlayerVM(bytes(2048)).m
names={0:'pose',1:'pose_scroll',2:'scroll_delta',3:'random_branch',4:'pose_scroll_delta',5:'wait',6:'wait',7:'wait',8:'wait'}
ext=['input_a_branch','input_b_branch','input_special_branch','memory_branch','held_guard','contact_target','clock','pose_accumulator_0','pose_accumulator_1','call','return','restore_health','sound','memory16_branch']
fops=['contact_wait','jump','unlock','loop','ready','set_loop','force','defense','increment',None,'write','effect_fixed','effect_tired','contact_flags',None,'halt']
lens=[2,3,0,1,0,1,1,2,1,0,2,0,0,1,0,0];elens=[1,1,1,3,1,1,1,1,1,2,0,0,1,4]
starts={str(s):m[a]+256*m[a+1] for s in list(range(1,22))+list(range(64,76))for a in [(0x9800+2*s)if s<64 else (0x982c+2*(s-64))]}
queue=[(p,0) for p in starts.values()if 0x9800<=p<0xa000];seen=set();commands={};invalid=[]
while queue:
 base,c=queue.pop();c&=255
 if (base,c)in seen:continue
 seen.add((base,c));pc=base+c
 if not 0x9800<=pc<0xa000:continue
 op=m[pc];hi=op>>4;lo=op&15
 if hi<9:n=[1,2,1,1,2,1,1,1,1][hi];name=names[hi]
 elif hi<15:
  if lo>=len(ext):invalid.append(pc);continue
  n=elens[lo];name=ext[lo]
 else:
  if fops[lo] is None:invalid.append(pc);continue
  n=lens[lo];name=fops[lo]
 args=m[pc+1:pc+1+n];node={'op':name,'arg':args,'duration':lo if hi<9 else None,'size':n+1}
 if name in ['force','defense','write']:
  node['chain']=m[pc+1+n]==0
  if node['chain']:node['size']+=1
 commands[str(pc)]=node;nextc=(c+node['size'])&255
 if name=='jump':queue.append((args[0]+256*args[1],args[2]));continue
 if name in ['halt','return','ready']:continue
 if name=='call':queue.append((args[0]+256*args[1],0))
 if name in ['random_branch','input_a_branch','input_b_branch','input_special_branch','held_guard','loop']:queue.append((base,args[0]))
 if name in ['memory_branch','memory16_branch']:queue.append((base,args[-1]))
 if name=='contact_wait':queue.extend((base,x)for x in args)
 # Opponent F8 and count handlers advance the suspended player cursor past this wait.
 queue.append((base,nextc))
result={'schema':1,'source':'bank11 animation VM; command operands and control flow only','states':starts,'commands':commands}
(root/'assets/data/player_animation_program.json').write_text(json.dumps(result,separators=(',',':')))
print('Exported',len(commands),'semantic commands; invalid branch targets',invalid)
