from pathlib import Path
from py65.devices.mpu6502 import MPU
from py65.disassembler import Disassembler
rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
mem=[0]*65536;mem[0xA000:]=rom[-0x6000:];mem[0x8000:0xA000]=rom[11*8192:12*8192];d=Disassembler(MPU(memory=mem))
out=[]
for lo,hi in [(0x8100,0x8190),(0x82CC,0x83C0)]:
 pc=lo
 while pc<hi:
  size,txt=d.instruction_at(pc);out.append(f'{pc:04X} [PRG {pc+0xE000:05X}] '+bytes(mem[pc:pc+size]).hex(' ')+' '+txt);pc+=size
Path('research/evidence/player_routines.txt').write_text('\n'.join(out))
