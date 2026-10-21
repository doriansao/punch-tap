"""Execute the ROM compositor offline to recover its finite visual transitions.
Output contains pose identifiers and measured geometry, never tile graphics/code.
"""
from pathlib import Path
from py65.devices.mpu6502 import MPU
import json,hashlib,collections
ROOT=Path('research/evidence/animation');rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
base=list((ROOT/'idle_long/full/ram.bin').read_bytes()[:2048])+[0]*(65536-2048);base[0x8000:0xa000]=rom[:8192];base[0xa000:]=rom[-0x6000:]
def run(m,selector,flip=0):
 m=m.copy();m[0xa0]=128;m[0xa1]=selector;m[0xa2]=flip;m[0x1fe]=254;m[0x1ff]=127
 cpu=MPU(memory=m);cpu.pc=0xc890;cpu.sp=0xfd
 for n in range(20000):
  if cpu.pc==0x7fff:return m
  cpu.step()
 raise RuntimeError(('compositor budget',selector,hex(cpu.pc)))
def signature(m):
 # The layout engine retains sprite positions as well as tile runs.
 # Ignore inaccessible attribute bits and hidden sprite tile bytes.
 b=[]
 for i in range(0x20c,0x300,4):
  if m[i]>=240:b.extend([248,0,0,0])
  else:b.extend([m[i],m[i+1],m[i+2]&227,m[i+3]])
 return bytes(b+[m[0xb2],m[0xb3],m[0xa9]])
full=list(range(0,60,2));partial=[128,130,192,194,196,204]
states=[];ids={};edges={};queue=[]
def add(m,origin):
 key=signature(m)
 if key not in ids:
  ids[key]=len(states);states.append((m,origin));queue.append(ids[key])
 return ids[key]
full_ids={}
for s in full:
 for flip in ([1] if s in [34,36,50,52,54,56] else [0]):full_ids[f'{s}:{flip}']=add(run(base,s,flip),[s,flip])
# Partial updates in the idle/guard family preserve the rest of the body.
for i in range(len(states)):
 m,origin=states[i]
 if origin[0]<=20:queue.append(i)
queue=list(dict.fromkeys(queue));visited=set()
while queue:
 i=queue.pop(0)
 if i in visited:continue
 visited.add(i);m,origin=states[i]
 if origin[0] not in [0,2,4,6,8,10,16,18,20]:continue
 edges[i]={}
 for s in (partial if origin[0] not in [18,20] else [198]):edges[i][s]=add(run(m,s),origin+[s])
 if len(states)>2000:raise RuntimeError('state explosion')
print('full',len(full_ids),'visual states',len(states),'partial transitions',sum(map(len,edges.values())))
# Research snapshots retained to reconstruct and inspect the output offline.
(ROOT/'opponent_composition_states.bin').write_bytes(b''.join(bytes(m[:2048])for m,_ in states))
(ROOT/'opponent_composition_graph.json').write_text(json.dumps({'full':full_ids,'edges':edges,'origins':[o for _,o in states]},indent=2))

