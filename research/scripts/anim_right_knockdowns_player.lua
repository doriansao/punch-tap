local root='G:/Programming/punch-tap/research/evidence/animation/right_knockdowns/player/'
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
local function input()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 b.up=true;b.b=true end end
 emu.setInput(b,0)
end
emu.addEventCallback(input,emu.eventType.inputPolled)
local ram=assert(io.open(root..'ram.bin','wb'))
emu.addEventCallback(function()
 n=n+1
 if n>=2295 then
  local bytes={};for a=0,2047 do bytes[#bytes+1]=string.char(r(a)) end;ram:write(table.concat(bytes))
  local f=assert(io.open(root..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n==7200 then ram:close();emu.stop(0) end
end,emu.eventType.endFrame)
