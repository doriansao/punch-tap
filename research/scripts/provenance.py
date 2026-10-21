import hashlib, json
from pathlib import Path

paths = ['G:/Programming/punch-out-ai/rom/punch-out.nes',
         'research/tools/mesen.zip', 'research/tools/mesen/Mesen.exe',
         'research/tools/mesen/settings.json']
result = dict(date='2026-10-20', emulator='Mesen 2.1.1 Windows',
              download='https://github.com/SourMesen/Mesen2/releases/download/2.1.1/Mesen_2.1.1_Windows.zip',
              disassembler='py65==1.2.0',
              method='Cold boot, NTSC, controller input, no RAM patches', files=[])
for name in paths:
    path = Path(name)
    result['files'].append(dict(path=str(path.resolve()), bytes=path.stat().st_size,
                               sha256=hashlib.sha256(path.read_bytes()).hexdigest()))
Path('research/evidence/provenance.json').write_text(json.dumps(result, indent=2))
