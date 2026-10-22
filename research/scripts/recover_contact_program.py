"""Export the reachable contact/count routines as decoded operations, not ROM bytes.

The restricted Godot executor preserves 8-bit flags and RAM side effects. Only
first-opponent gameplay tables are exported; no graphics, audio or ROM image.
"""
from pathlib import Path
import json
from py65.devices.mpu6502 import MPU

root=Path(__file__).resolve().parents[2]
rom=Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
mem=[0]*65536
mem[0x8000:0xa000]=rom[7*8192:8*8192]
mem[0xa000:]=rom[-0x6000:]
cpu=MPU(memory=mem)
lengths={'imp':1,'acc':1,'imm':2,'zpg':2,'zpx':2,'zpy':2,'rel':2,'inx':2,'iny':2,'abs':3,'abx':3,'aby':3,'ind':3}
todo=[0xb5a9,0x805d,0xb2eb,0xb069,0xb10a,0xb196,0x8759,0x86d0,0x881e,0x890d,0x8974]; nodes={}
while todo:
    pc=todo.pop()
    if str(pc) in nodes: continue
    op,mode=cpu.disassemble[mem[pc]]
    assert op!='???',(hex(pc),mem[pc])
    size=lengths[mode]; arg=mem[pc+1] if size>1 else 0
    if size==3: arg+=mem[pc+2]*256
    nxt=pc+size
    if op=='JSR' and arg==0xaed4:
        targets={0xb1b8:[0xb1c1,0xb1ce,0xb1df],0xb23d:[0xb24a,0xb250,0xb259,0xb26a,0xb273]}[pc]
        nodes[str(pc)]={'op':'DISPATCH','mode':'imp','arg':0,'next':nxt,'targets':targets}
        todo.extend(targets);continue
    if mode=='rel':arg=nxt+(arg if arg<128 else arg-256)
    nodes[str(pc)]={'op':op,'mode':mode,'arg':arg,'next':nxt}
    if op=='RTS':continue
    if op=='JMP':todo.append(arg);continue
    if op=='JSR' or mode=='rel':todo.append(arg)
    if pc==0x87fc:continue # unconditional branch after LDA #$2B; table follows
    todo.append(nxt)
tables={}
for lo,hi in [(0x9316,0x94c3)]:
    for address in range(lo,hi):tables[str(address)]=rom[address-0x8000]
for address in range(0xb393,0xb3a3):tables[str(address)]=mem[address]
for address in range(0x87fe,0x8806):tables[str(address)]=mem[address]
for address in range(0x89fd,0x8a12):tables[str(address)]=mem[address]
out={'entry':0x805d,'operations':nodes,'tables':tables,'scope':'Bank 7 contact routine and fixed-bank combo/count helpers; first opponent tables only.'}
(root/'assets/data/contact_program.json').write_text(json.dumps(out,separators=(',',':'))+'\n')
print(len(nodes),'decoded operations;',len(tables),'gameplay table values')
