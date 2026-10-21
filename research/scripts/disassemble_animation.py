from pathlib import Path
from py65.devices.mpu6502 import MPU
from py65.disassembler import Disassembler
rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
mem=[0]*65536;mem[0xA000:]=rom[-0x6000:];mem[0x8000:0xA000]=rom[7*8192:8*8192];d=Disassembler(MPU(memory=mem))
out=[]
for lo,hi in [(0xC46B,0xC560),(0xC940,0xC9D0),(0xD140,0xD1C0),(0x83A0,0x83D0),(0x84E0,0x8580)]:
 pc=lo
 while pc<hi:
  size,txt=d.instruction_at(pc);out.append(f'{pc:04X} '+bytes(mem[pc:pc+size]).hex(' ')+' '+txt);pc+=size
Path('research/evidence/animation_and_damage.txt').write_text('\n'.join(out))
