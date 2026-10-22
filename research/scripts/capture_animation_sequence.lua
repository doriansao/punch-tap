local n=0
local pending=nil
local finished=false
local function r(a)return emu.read(a,emu.memType.nesDebug)end
local function dump()local b={};for a=0,2047 do b[#b+1]=string.char(r(a))end;return table.concat(b)end
emu.addEventCallback(function()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
 emu.setInput(b,0)
end,emu.eventType.inputPolled)
emu.addEventCallback(function()
 n=n+1
 if n>=2290 and n<=2410 then
  local f=assert(io.open('G:/Programming/punch-tap/research/evidence/sequence_audit/rom/'..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n==2410 then emu.stop(0)end
end,emu.eventType.endFrame)
