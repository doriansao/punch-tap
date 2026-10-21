from pathlib import Path
from py65.devices.mpu6502 import MPU
import random,json
rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
def permute(value,bits):return sum(((value>>i)&1)<<out for i,out in enumerate(bits))
def rng(frame,buttons,acc):
 acc=(acc+permute(buttons,[0,7,1,5,2,6,3,4]))&255
 return (permute(frame,[7,0,6,1,5,2,4,3])+permute(acc,[0,2,4,6,1,3,5,7]))&255,acc
r=random.Random(251);cases=[]
for _ in range(2048):
 frame=r.randrange(256);buttons=r.randrange(256);acc=r.randrange(256);m=[0]*65536;m[0x8000:0xa000]=rom[7*8192:8*8192];m[0x1e]=frame;m[0xd0]=buttons;m[0x19]=acc;m[0x1fe]=0xfe;m[0x1ff]=0x7f;cpu=MPU(memory=m);cpu.pc=0x85e9;cpu.sp=0xfd;cpu.p|=r.randrange(2)
 for i in range(1000):
  if cpu.pc==0x7fff:break
  cpu.step()
 actual=(m[0x18],m[0x19]);expected=rng(frame,buttons,acc);assert actual==expected,(frame,buttons,acc,actual,expected)
 cases.append([frame,buttons,acc,*actual])
Path('research/evidence/animation/rng_cases.json').write_text(json.dumps(cases));print('2048 RNG permutation cases match original bank-7 routine, both carry inputs')
