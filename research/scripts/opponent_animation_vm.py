"""Semantic opponent command decoder; differential tests at $C550 boundaries."""
from pathlib import Path
import struct,json
from player_animation_vm import ROM
class OpponentVM:
 def __init__(self,ram):
  self.m=list(ram)+[0]*(65536-len(ram));self.m[0x8000:0xa000]=ROM[:8192];self.m[0xa000:]=ROM[-0x6000:]
 def read(self):
  m=self.m;p=m[0x94]+256*m[0x95];c=m[0x93];m[0x93]=(c+1)&255;return m[p+c]
 def chain(self):
  m=self.m
  if m[m[0x94]+256*m[0x95]+m[0x93]]==0:m[0x93]=(m[0x93]+1)&255
 def move(self,v):
  m=self.m
  for a,d in [(0xb0,v>>4),(0xb1,v&15)]:m[a]=(m[a]+(d if d<8 else d-16))&255
  m[0xa0]=1;self.chain()
 def step(self):
  m=self.m;op=self.read();hi=op>>4;lo=op&15
  if hi in [0,4]:
   if hi==4:m[0xa2]=1
   m[0x92]=lo;m[0xa1]=self.read();m[0xa0]=128;self.chain()
  elif hi in [1,2,5]:
   if hi==5:m[0xa2]=1
   m[0x92]=lo
   if hi!=2:m[0xa1]=self.read();m[0xa0]=128
   m[0xb0]=self.read();m[0xb1]=self.read()
  elif hi==3:
   dest=self.read();old=m[0x18];carry=0
   if lo!=15:
    for k in range(3):carry,m[0x18]=m[0x18]&1,(m[0x18]>>1)|(carry<<7)
   if lo==15 or lo>(old&15):m[0x93]=dest
  elif hi==6:m[0x92]=lo;self.move(self.read())
  elif hi==7:m[0x92]=(lo&3)+1;m[0x9b]=m[0x92];m[0x9a]=(lo>>2)+1;self.move(self.read())
  elif hi==8:m[0x92]=self.read()
  elif hi==9:
   a=self.read();page=self.read()*256
   for _ in range(lo or 256):m[page+a]=self.read();a=(a+1)&255
  elif hi==10:
   m[0x92]=lo
   for i in range(2):
    a=m[0xb0+i];target=m[0x4d0+i];delta=(a-target)&255;delta=delta if delta<128 else delta-256;step=min(abs(delta),m[0x4d2+i]);m[0xb0+i]=(a+step if delta<0 else a-step)&255
   dest=self.read()
   if m[0xb0:0xb2]==m[0x4d0:0x4d2]:m[0x93]=dest
  elif hi<15:
   if lo==0:
    m[0x9e:0xa0]=m[0x94:0x96];a=self.read();b=self.read();m[0x9d]=m[0x93];m[0x94:0x96]=[a,b];m[0x93]=0
   elif lo==1:m[0x94:0x96]=m[0x9e:0xa0];m[0x93]=m[0x9d];m[0x9f]=0
   elif lo==4:m[0x92]=m[0x581]
   elif lo==5:m[0x97]=0
   elif lo==6:m[0x10]&=223;m[0x80]=8
   elif lo==7:m[0x10]|=32;m[0x80]=16
   elif lo==8:
    a=self.read()+256*self.read();v=self.read();dest=self.read()
    if m[a]==v:m[0x93]=dest
   elif lo==9:
    v=self.read()
    if v and not m[0x300]:m[0x300]=v
    m[0x301]=(m[0x301]&254)|(v^1);m[0x306]=100
   elif lo==12:
    v=self.read();a=0xf0+(v&3);v&=252;m[a]=v if v&128 else v>>2
   else:raise ValueError(hex(op))
  elif lo==0:
   v=m[0x98]
   if v==0:m[0x98]=128
   if not v or v&128:m[0x93]=(m[0x93]-1)&255
   elif v==3:m[0x93]=(m[0x93]+3)&255;m[0x98]=0
   else:
    i=v-1 if v<3 else v-2;p=m[0x94]+256*m[0x95];m[0x93]=m[p+((m[0x93]+i)&255)];m[0x98]=0
  elif lo==1:
   a=self.read();b=self.read();c=self.read();m[0x94:0x96]=[a,b];m[0x93]=c
  elif lo==2:
   a=self.read();v=self.read();dest=self.read()
   if m[a]==v:m[0x93]=dest
  elif lo==3:
   dest=self.read();m[0x96]=(m[0x96]-1)&255
   if m[0x96]:m[0x93]=dest
  elif lo==4:m[0x90]=129
  elif lo==5:m[0x96]=self.read()
  elif lo==6:m[0xb4]=self.read();m[0xb5]=self.read();self.chain()
  elif lo==7:
   for a in range(0xb6,0xba):m[a]=self.read()
   self.chain()
  elif lo==8:m[0x53]=(m[0x53]+2)&255;m[0x52]=1
  elif lo==9:m[0x97]=1
  elif lo==10:a=self.read();m[a]=self.read();self.chain()
  elif lo==11:m[0x4a]=m[0x585]
  elif lo==12:
   if m[0x4a]:m[0x93]=(m[0x93]-1)&255
  elif lo==13:m[0x5a]=self.read()
  elif lo==14:m[0x91]=130
  elif lo==15:m[0x93]=(m[0x93]-1)&255;m[0x91]=131
  return op

def validate():
 total=failures=0;examples=[];coverage=set()
 checked=list(range(0x90,0xba))+list(range(0x4a,0x4d))+[0x10,0x18,0x80,0x52,0x53,0x5a]+list(range(0xf0,0xf4))+list(range(0x300,0x307))
 for p in Path('research/evidence/animation').glob('*_opponent_vm.bin'):
  data=p.read_bytes();assert len(data)%4100==0
  for off in range(0,len(data),4100):
   f=struct.unpack_from('<I',data,off)[0];before=data[off+4:off+2052];after=data[off+2052:off+4100];vm=OpponentVM(before);op=vm.step();coverage.add(op);total+=1
   diffs=[(hex(a),vm.m[a],after[a])for a in checked if vm.m[a]!=after[a]]
   if diffs:
    failures+=1
    if len(examples)<20:examples.append({'case':p.stem,'frame':f,'op':hex(op),'diff':diffs})
 report={'commands':total,'failures':failures,'examples':examples,'covered_opcodes':[hex(x)for x in sorted(coverage)]};Path('research/evidence/animation/opponent_vm_validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
if __name__=='__main__':validate()
