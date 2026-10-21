"""Independent semantic model of bank 11 animation interpreter ($82CC-$8602).
Research only: validates against function entry/return snapshots, not end-frame guesses.
"""
from pathlib import Path
import json,struct
ROM=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
class PlayerVM:
 def __init__(self,ram):
  self.m=list(ram)+[0]*(65536-len(ram));self.m[0x8000:0xa000]=ROM[11*8192:12*8192];self.m[0xa000:]=ROM[-0x6000:];self.ops=[]
 def read(self):
  m=self.m;p=m[0x54]+256*m[0x55];c=m[0x53];m[0x53]=(c+1)&255;return m[(p+c)&65535]
 def setpose(self,v):self.m[0x61]=v;self.m[0x60]=128
 def step(self):
  m=self.m
  if m[0x50]==0:return
  if m[0x50]&128:
   m[0x50]&=127;m[0x51]|=128;m[0x52]=1
   for a in [0x53,0x56,0x58,0x59,0x74,0x75,0x76,0x77]:m[a]=0
   m[0x5b]=int(m[0x4a]!=0 and m[0x4b]!=0)
   a=0x9800+2*m[0x50] if m[0x50]<64 else 0x982c+2*(m[0x50]-64)
   m[0x54:0x56]=m[a:a+2]
  m[0x52]=(m[0x52]-1)&255
  if m[0x52]:return
  m[0x52]=1
  for _ in range(1000):
   pc=m[0x54]+256*m[0x55]+m[0x53];op=self.read();self.ops.append((pc,op));hi=op>>4;lo=op&15
   if hi==0:self.setpose(self.read());m[0x52]=lo;return
   if hi==1:
    m[0x52]=lo;pose=self.read();m[0x61]=pose;m[0x15]=self.read()
    if m[0x15]:m[0x60]=128;return
    # Actual fallthrough at zero scroll enters additive handler.
    m[0x15]=(m[0x15]+self.read())&255;return
   if hi==2:m[0x52]=lo;m[0x15]=(m[0x15]+self.read())&255;return
   if hi==3:
    dest=self.read();old=m[0x18]
    if lo!=15:
     carry=0
     for k in range(3):carry,m[0x18]=m[0x18]&1,(m[0x18]>>1)|(carry<<7)
    if lo==15 or lo>=(old&15)+1:m[0x53]=dest
    continue
   if hi==4:self.setpose(self.read());m[0x52]=lo;m[0x15]=(m[0x15]+self.read())&255;return
   if hi in [5,6,7,8]:m[0x52]=self.read();return
   if hi<15:
    if lo in [0,1,2]:
     dest=self.read()
     if m[0xd3]&128 and m[0xd2]&[9,10,4][lo]:m[0xd3]&=127;m[0x53]=dest
    elif lo in [3,13]:
     addr=self.read()
     if lo==13:addr+=256*self.read()
     value=self.read();dest=self.read()
     if m[addr]==value:m[0x53]=dest
    elif lo==4:
     dest=self.read();d=m[0xd3]
     if m[0x6a]==0:
      if not d&129:m[0x6a]=1
     elif m[0x6a]&128:
      if not d&129:m[0x50]=129 if m[0xbc] else 130
     elif d&128 and m[0xd2]&4:m[0xd3]&=127;m[0x50]=14;m[0x53]=dest;continue
     return
    elif lo==5:m[0x99]=1;m[0x74]=self.read();return
    elif lo==6:
     v=self.read()
     if v and not m[0x300]:m[0x300]=v
     m[0x301]=(m[0x301]&254)|(v^1);return
    elif lo in [7,8]:
     addr=0x70+lo-7;m[addr]=(m[addr]+self.read())&255;self.setpose(m[addr]);return
    elif lo==9:
     m[0x7e:0x80]=m[0x54:0x56];low=self.read();high=self.read();m[0x7d]=m[0x53];m[0x54:0x56]=[low,high];m[0x53]=0
    elif lo==10:m[0x54:0x56]=m[0x7e:0x80];m[0x53]=m[0x7d]
    elif lo==11:m[0x391]=m[0x397];m[0x398]=m[0x39e]
    elif lo==12:
     v=self.read();a=0xf0+(v&3);v&=252;m[a]=v if v&128 else v>>2
    else:raise ValueError(('invalid E',hex(pc),hex(op)))
    continue
   if lo==0:
    contact=m[0x58]
    if contact==0:m[0x58]=128+int(m[0x5b]!=0)
    if contact==0 or contact&128:m[0x53]=(m[0x53]-1)&255;return
    a=self.read();b=self.read()
    if contact==1:m[0x53]=a
    elif contact==2:m[0x53]=b
    m[0x58]=0
   elif lo==1:
    a=self.read();b=self.read();c=self.read();m[0x54:0x56]=[a,b];m[0x53]=c;m[0x58]=0
   elif lo==2:m[0x51]&=127
   elif lo==3:
    dest=self.read();m[0x56]=(m[0x56]-1)&255
    if m[0x56]:m[0x53]=dest
   elif lo==4:m[0x50]=(130-m[0xbc])&255;return
   elif lo==5:m[0x56]=self.read();return
   elif lo in [6,7,10]:
    if lo==6:m[0x75]=self.read()
    elif lo==7:m[0x76]=self.read();m[0x77]=self.read()
    else:a=self.read();m[a]=self.read()
    ptr=m[0x54]+256*m[0x55]+m[0x53]
    if m[ptr]!=0:return
    m[0x53]=(m[0x53]+1)&255
   elif lo==8:a=self.read();m[a]=(m[a]+1)&255
   elif lo in [11,12]:
    m[0x48d]=48 if lo==11 else m[0x4a1];m[0x48e]=143 if lo==11 or m[0xbc] else 20;m[0x4a0]=129
   elif lo==13:m[0x59]=self.read()
   elif lo==15:m[0x53]=(m[0x53]-1)&255;m[0x51]=131;return
   else:raise ValueError(('invalid F',hex(pc),hex(op)))
  raise RuntimeError('animation loop')

def validate():
 total=0;bad=[];coverage=set()
 # Scratch/CPU stack bytes are intentionally excluded; actor state and every
 # persistent side effect are compared independently at the function boundary.
 checked=list(range(0x50,0x80))+[0x15,0x18,0x99,0xbc,0xd3]+list(range(0xf0,0xf4))+[0x300,0x301,0x391,0x398,0x48d,0x48e,0x4a0]
 for p in Path('research/evidence/animation').glob('*_vm.bin'):
  if '_opponent_' in p.name:continue
  b=p.read_bytes();assert len(b)%4100==0
  for off in range(0,len(b),4100):
   f=struct.unpack_from('<I',b,off)[0];before=b[off+4:off+2052];after=b[off+2052:off+4100]
   vm=PlayerVM(before);vm.step();coverage.update(op for _,op in vm.ops);total+=1
   diffs=[(hex(a),vm.m[a],after[a])for a in checked if vm.m[a]!=after[a]]
   if diffs and len(bad)<30:bad.append({'case':p.stem,'frame':f,'diff':diffs,'ops':[(hex(pc),hex(op))for pc,op in vm.ops]})
 report={'function_calls':total,'failed_examples':bad,'covered_opcodes':[hex(x)for x in sorted(coverage)]}
 Path('research/evidence/animation/player_vm_validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
if __name__=='__main__':validate()
