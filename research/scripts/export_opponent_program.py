from pathlib import Path
import json
from opponent_animation_vm import OpponentVM
m=OpponentVM(bytes(2048)).m
hi_names=['pose','pose_position','position','random_branch','pose_alt','pose_position_alt','move','move_repeat','wait','write_block','approach']
hi_lengths=[1,3,2,1,1,3,1,1,1,0,1]
ext_names=['call','return',None,None,'speed_wait','clear_flag','small_sprites','large_sprites','memory16_branch','clock',None,None,'sound']
ext_lengths=[2,0,0,0,0,0,0,0,4,1,0,0,1]
f_names=['contact_wait','jump','memory_branch','loop','ready','set_loop','force','defense','release_player','set_flag','write','lock_player','wait_player','player_hit_flag','end','halt']
f_lengths=[3,3,3,1,0,1,2,4,0,0,2,0,0,1,0,0]
starts={}
for s in list(range(1,28))+[64,65]:
 a=0x8002 if s<64 else 0x8004;p=m[a]+256*m[a+1];i=s if s<64 else s-64;p=m[p+2*i]+256*m[p+2*i+1]
 if p:starts[str(s)]=p
queue=[(p,0)for p in starts.values()];seen=set();commands={};invalid=[]
while queue:
 base,c=queue.pop();c&=255
 if (base,c)in seen:continue
 seen.add((base,c));pc=base+c
 if not 0x8000<=pc<0xa000:continue
 op=m[pc];hi=op>>4;lo=op&15
 if hi<11:name=hi_names[hi];n=2+(lo or 256)if hi==9 else hi_lengths[hi]
 elif hi<15:
  if lo>=len(ext_names)or ext_names[lo]is None:invalid.append(pc);continue
  name=ext_names[lo];n=ext_lengths[lo]
 else:name=f_names[lo];n=f_lengths[lo]
 args=m[pc+1:pc+1+n];node={'op':name,'arg':args,'duration':lo,'size':n+1}
 if name in ['pose','pose_alt','move','move_repeat','force','defense','write']:
  node['chain']=m[pc+n+1]==0
  if node['chain']:node['size']+=1
 commands[str(pc)]=node;nextc=(c+node['size'])&255
 if name=='jump':queue.append((args[0]+256*args[1],args[2]));continue
 if name in ['return','ready','halt']:continue
 if name=='call':queue.append((args[0]+256*args[1],0))
 if name in ['random_branch','approach','loop']:queue.append((base,args[0]))
 if name in ['memory_branch','memory16_branch']:queue.append((base,args[-1]))
 if name=='contact_wait':queue.extend((base,v)for v in args)
 if not(name=='random_branch' and lo==15):queue.append((base,nextc))
out={'schema':1,'source':'fixed-bank opponent animation VM; named commands only','states':starts,'commands':commands}
Path('assets/data/opponent_animation_program.json').write_text(json.dumps(out,separators=(',',':')))
print(len(commands),'commands; invalid',invalid)

