local n=0
local pending=nil
local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/coupled_idle.bin','wb'))
local function r(a)return emu.read(a,emu.memType.nesDebug)end
local function dump()local b={};for a=0,2047 do b[#b+1]=string.char(r(a))end;return table.concat(b)end
emu.addEventCallback(function()emu.setInput({a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false},0)end,emu.eventType.inputPolled)
emu.addMemoryCallback(function()if n>=2017 and n<4200 and r(4)==255 and r(5)==0 then pending={frame=n+1,ram=dump()}end end,emu.callbackType.exec,0xA669)
emu.addMemoryCallback(function()if pending then out:write(string.pack('<I4',pending.frame),pending.ram,dump());pending=nil end end,emu.callbackType.exec,0xA6C9)
emu.addEventCallback(function()n=n+1;if n==4200 then out:close();emu.stop(0)end end,emu.eventType.endFrame)
