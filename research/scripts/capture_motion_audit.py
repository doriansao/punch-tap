"""Read-only ROM screenshots from existing input strategies; never replace fixtures."""
from pathlib import Path
import json, subprocess
root=Path(__file__).resolve().parents[2]
clips=json.loads((root/'research/scripts/motion_audit_clips.json').read_text())
out=root/'research/evidence/motion_audit';out.mkdir(parents=True,exist_ok=True)
for fixture in ['full','defense','getup']:
    selected=[c for c in clips if c['fixture']==fixture]
    folder=out/fixture/'rom';folder.mkdir(parents=True,exist_ok=True)
    original=(root/f'research/scripts/capture_{fixture}_fight.lua').read_text()
    program=original.split('emu.addMemoryCallback',1)[0]
    program='\n'.join(line for line in program.splitlines() if not line.startswith('local out='))
    condition=' or '.join(f"(n>={c['start']} and n<={c['end']})" for c in selected)
    program+=f"""
emu.addEventCallback(function()
 n=n+1
 if {condition} then
  local f=assert(io.open('{folder.as_posix()}/'..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n=={max(c['end'] for c in selected)} then emu.stop(0) end
end,emu.eventType.endFrame)
"""
    script=out/f'capture_{fixture}.lua';script.write_text(program)
    with (out/f'rom_{fixture}.log').open('w') as log:
        result=subprocess.run([str(root/'research/tools/mesen/Mesen.exe'),'--testRunner','G:/Programming/punch-out-ai/rom/punch-out.nes',str(script),'--timeout=180'],stdout=log,stderr=subprocess.STDOUT,timeout=200)
    assert result.returncode==0,(fixture,result.returncode)
    for clip in selected:
        assert all((folder/f'{n}.png').exists() for n in range(clip['start'],clip['end']+1)),clip
    print('ROM motion capture',fixture,'complete',flush=True)
