from pathlib import Path
import csv
from py65.devices.mpu6502 import MPU
from py65.disassembler import Disassembler
rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
# Fixed upper 24 KiB, mapper9 switchable 8KiB selected from observed physical offsets.
out=[]
for lo,hi,bank in [(0xB180,0xB220,0),(0xB400,0xB450,0),(0xB630,0xB680,0),(0xC440,0xC490,0)]:
 mem=[0]*65536;mem[0xA000:]=rom[-0x6000:];mem[0x8000:0xA000]=rom[bank*8192:(bank+1)*8192]
 d=Disassembler(MPU(memory=mem));pc=lo
 while pc<hi:
  size,txt=d.instruction_at(pc);out.append(f'{pc:04X}  '+bytes(mem[pc:pc+size]).hex(' ')+'  '+txt);pc+=size
Path('research/evidence/routines.txt').write_text('\n'.join(out))
