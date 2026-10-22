"""ROM-executed isolated arm-lowering loop; not a natural-input fight trace."""
from pathlib import Path
import json
from py65.devices.mpu6502 import MPU
root=Path(__file__).resolve().parents[2]
r=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
m=[0]*65536;m[0x8000:0xa000]=r[11*8192:12*8192];m[0xa000:]=r[-0x6000:]
m[0x50]=65;m[0x51]=129;m[0x52]=1;m[0x54]=0xb5;m[0x55]=0x9d;m[0x53]=0x9e13-0x9db5
initial=m[:2048];rows=[]
for frame in range(70):
    m[0x60]=0;m[0x1fe:0x200]=[254,127]
    cpu=MPU(memory=m);cpu.pc=0x8319;cpu.sp=253
    for _ in range(2000):
        if cpu.pc==0x7fff:break
        cpu.step()
    else:raise RuntimeError('Interpreter did not return')
    rows.append({'frame':frame,'ram':m[:256]})
out=root/'research/evidence/animation/referee_partial_execution.json'
out.write_text(json.dumps({'scope':'Isolated original bank-11 interpreter, entry at decoded wave loop $9E13, no natural reachability claim.','initial':initial,'frames':rows}))
print('ROM-executed partial referee loop:',len(rows),'ticks')
