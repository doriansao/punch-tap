from pathlib import Path
import json
ROOT=Path('research/evidence')
def sample(case,frame,address):return (ROOT/(case+'_ram.bin')).read_bytes()[(frame-2295)*2048+address]
def track(case,start,stop):
 b=(ROOT/(case+'_ram.bin')).read_bytes()
 return [{ 'defense':list(b[(f-2295)*2048+0xB6:(f-2295)*2048+0xBA]),'ko':b[(f-2295)*2048+0xBA], 'clock_pause':bool(b[(f-2295)*2048+0x301]&1)} for f in range(start,stop)]
profiles={}
for name,state in [('left_body',9),('right_body',10),('left_head',11),('right_head',12),('dodge_left',5),('dodge_right',3),('down',7)]:
 b=(ROOT/(name+'_ram.bin')).read_bytes();frames=[i for i in range(len(b)//2048) if b[i*2048+0x50]==state];first,last=frames[0],frames[-1]
 contact=[i-first for i in frames if b[i*2048+0x58]]
 profiles[name]={'state':state,'duration':last-first+1,'contact_at':contact[0] if contact else -1,'defense':[list(b[i*2048+0x76:i*2048+0x78]) for i in frames]}
 if contact:
  p=(first+contact[0]-1)*2048;profiles[name].update(force=b[p+0x75],target=b[p+0x74]&3)
profiles['special']={'state':13,'duration':88,'contact_at':43,'defense':[[0,0]]*88,'force':15,'target':0}
r=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
schedules={}
for name,start,end in [('normal',0x9478,0x9496),('fast',0x949B,0x94B9),('tired',0x94B9,0x94C3)]:
 ops={};a=start
 while a<end:
  o=r[a-0x8000];hi,lo=o>>4,o&15;size=1
  if hi==0:size=2;cmd={'op':'attack','id':r[a+1-0x8000]&127,'delay':lo}
  elif hi==1:size=2;cmd={'op':'branch','threshold':lo,'target':r[a+1-0x8000]}
  elif hi==8:
   size=2 if lo==0 else 1;cmd={'op':'wait','frames':r[a+1-0x8000] if lo==0 else lo*4}
  elif o==0xF1:cmd={'op':'enable'}
  else:raise ValueError(hex(o))
  cmd['next']=a-start+size;ops[str(a-start)]=cmd;a+=size
 schedules[name]=ops
rules={'provenance':'ROM traces and decoded Glass Joe scheduling data; see research/RECOVERY_UPDATE.txt','player':profiles,'opponent':{
 'jab':{'state':21,'duration':85,'contact_at':44,'track':track('idle_long',2963,3048)},
 'cross':{'state':22,'duration':97,'contact_at':58,'track':track('idle_long',3265,3362)},
 'taunt_long':{'state':25,'duration':163,'contact_at':-1,'track':track('idle_long',2798,2961)},
 'taunt_short':{'state':25,'duration':134,'contact_at':-1,'track':track('normal_knockdowns',2798,2932)}},'schedules':schedules,
 'opponent_getup_counts':[2,3,4,5,6,8,3,4],
 'player_getup_tables':[[0x07,0x25,0x39,0x25,0x39,0x25,0x39,0x25,0x39,0x25],[0x07,0x12,0x26,0x12,0x26,0x12,0x26,0x12,0x26,0x12]]}
Path('assets/data/recovered_rules.json').write_text(json.dumps(rules,indent=2))
print('Built semantic rules; no ROM graphics or executable bytes included.')
