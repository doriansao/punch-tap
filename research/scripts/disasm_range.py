from pathlib import Path
from py65.devices.mpu6502 import MPU
from py65.disassembler import Disassembler
import argparse
p=argparse.ArgumentParser();p.add_argument('bank',type=int);p.add_argument('start',type=lambda x:int(x,16));p.add_argument('end',type=lambda x:int(x,16));a=p.parse_args()
r=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088];m=[0]*65536;m[0xA000:]=r[-0x6000:];m[0x8000:0xA000]=r[a.bank*8192:(a.bank+1)*8192];d=Disassembler(MPU(memory=m));pc=a.start
while pc<a.end:
 n,t=d.instruction_at(pc);print(f'{pc:04X} {bytes(m[pc:pc+n]).hex(" "):9} {t}');pc+=n
