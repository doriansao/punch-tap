"""Prepare isolated-layer captures and matching RAM; use ordinary pad input."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
cases={'visual_audit':(2295,3400),'normal_knockdowns':(2295,7200),'player_getup_wide':(4000,4550),'idle_long':(2295,3400)}
for name,(start,end) in cases.items():
 source=(root/'scripts'/f'{name}.lua').read_text()
 if name=='visual_audit':
  inp=source[source.index('emu.addEventCallback(function()'):source.index('end,emu.eventType.inputPolled)')+len('end,emu.eventType.inputPolled)')]
 else:
  inp=source[source.index('local function input()'):source.index('emu.addEventCallback(input,emu.eventType.inputPolled)')+len('emu.addEventCallback(input,emu.eventType.inputPolled)')]
 for layer in ['full','player','opponent']:
  out=root/'evidence/animation'/name/layer;out.mkdir(parents=True,exist_ok=True)
  lua=f"local root='{out.as_posix()}/'\nlocal n=0\nlocal function r(a) return emu.read(a,emu.memType.nesDebug) end\n"+inp+f'''
local ram=assert(io.open(root..'ram.bin','wb'))
emu.addEventCallback(function()
 n=n+1
 if n>={start} then
  local bytes={{}};for a=0,2047 do bytes[#bytes+1]=string.char(r(a)) end;ram:write(table.concat(bytes))
  local f=assert(io.open(root..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n=={end} then ram:close();emu.stop(0) end
end,emu.eventType.endFrame)
'''
  (root/'scripts'/f'anim_{name}_{layer}.lua').write_text(lua)
print('Prepared nine ordinary-input capture scripts')
