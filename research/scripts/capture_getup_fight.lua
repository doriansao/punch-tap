local n=0
local pending=nil
local finished=false
local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/coupled_getup_fight.bin','wb'))
local function r(a)return emu.read(a,emu.memType.nesDebug)end
local function dump()local b={};for a=0,2047 do b[#b+1]=string.char(r(a))end;return table.concat(b)end
emu.addEventCallback(function()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=false;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
 if r(5)==2 then b.a=n%4<2;b.b=false;b.start=false;b.up=false end
 emu.setInput(b,0)
end,emu.eventType.inputPolled)
emu.addMemoryCallback(function()if n>=2017 and n<6000 and r(4)==255 then pending={frame=n+1,ram=dump()}end end,emu.callbackType.exec,0xA669)
emu.addMemoryCallback(function()if pending then out:write(string.pack('<I4',pending.frame),pending.ram,pending.input or string.rep(string.char(0),10),dump());pending=nil;if r(0)>=251 then finished=true end end end,emu.callbackType.exec,0xA6C9)
emu.addMemoryCallback(function()if pending then local b={};for a=0xD0,0xD9 do b[#b+1]=string.char(r(a))end;pending.input=table.concat(b)end end,emu.callbackType.exec,0xA682)
emu.addEventCallback(function()
 n=n+1
 if n>=4200 and n%8==0 then
  local f=assert(io.open('G:/Programming/punch-tap/research/evidence/getup_audit/rom/'..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if finished or n==6000 then out:close();emu.stop(0)end
end,emu.eventType.endFrame)
