"""Execute KO entry/coordinator routines in the supplied ROM; no inferred outputs."""
from pathlib import Path
from random import Random
import json
from py65.devices.mpu6502 import MPU

rom = Path('G:/Programming/punch-out-ai/rom/punch-out.nes').read_bytes()[16:131088]
rng = Random(8404)
cases = []
fields = list(range(256)) + list(range(0x200, 0x800))  # CPU stack is call machinery.
for kind, address, count in [('player', 0x83eb, 256), ('opponent', 0x8404, 256), ('coordinator', 0xb549, 1024)]:
    for i in range(count):
        before = [rng.randrange(256) for _ in range(2048)]
        if kind == 'coordinator':
            before[0x301] = (0, 1, 128, 129)[i % 4]
            before[0x343] = (0, 1, 128, 255)[i // 4 % 4]
            before[5] = (0, 1, 2, 0)[i // 16 % 4]
            before[0x51] = (0, 1, 129, 130, 131, 255)[i // 64 % 6]
            before[0x91] = (0, 1, 129, 130, 131, 255)[i // 7 % 6]
            before[0x90] = (0, 1, 129)[i // 3 % 3]
            before[0xbc] = i % 2
        memory = before + [0] * (65536 - 2048)
        memory[0x8000:0xa000] = rom[7*8192:8*8192]
        memory[0xa000:] = rom[-0x6000:]
        memory[0x1fe:0x200] = [254, 127]
        cpu = MPU(memory=memory); cpu.pc = address; cpu.sp = 253
        for _ in range(1000):
            if cpu.pc == 0x7fff: break
            cpu.step()
        else: raise RuntimeError(f'{kind} execution exceeded budget')
        cases.append({'kind':kind, 'before':before, 'after':[memory[a] for a in fields]})
out = Path('research/evidence/animation/knockdown_entry_cases.json')
out.write_text(json.dumps({'fields':fields,'cases':cases}, separators=(',',':')))
print(f'{len(cases)} ROM-executed cases -> {out}')
