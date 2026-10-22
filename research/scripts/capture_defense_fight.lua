local n=0
local pending=nil
local attackStart=-1000
local attackNumber=0
local lastState=0
local finished=false
local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/coupled_defense_fight.bin','wb'))
local function r(a)return emu.read(a,emu.memType.nesDebug)end
local function dump()local b={};for a=0,2047 do b[#b+1]=string.char(r(a))end;return table.concat(b)end
emu.addEventCallback(function()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 then
  local state=r(0x90)%128
  if state==21 and lastState~=21 then attackStart=n;attackNumber=attackNumber+1 end
  local age=n-attackStart
  if state==21 then
   if attackNumber%3==1 then b.down=true
   elseif age>=22 and age<40 then
    if attackNumber%3==2 then b.left=true else b.right=true end
   end
   if age>=48 and age<51 then b.a=true;b.down=false end
  end
  lastState=state
 end
 emu.setInput(b,0)
end,emu.eventType.inputPolled)
emu.addMemoryCallback(function()if n>=2017 and n<4200 and r(4)==255 then pending={frame=n+1,ram=dump()}end end,emu.callbackType.exec,0xA669)
emu.addMemoryCallback(function()if pending then out:write(string.pack('<I4',pending.frame),pending.ram,pending.input or string.rep(string.char(0),10),dump());pending=nil;if r(0)>=251 then finished=true end end end,emu.callbackType.exec,0xA6C9)
emu.addMemoryCallback(function()if pending then local b={};for a=0xD0,0xD9 do b[#b+1]=string.char(r(a))end;pending.input=table.concat(b)end end,emu.callbackType.exec,0xA682)
emu.addEventCallback(function()
 n=n+1
 if n>=2900 and n%4==0 then
  local f=assert(io.open('G:/Programming/punch-tap/research/evidence/defense_audit/rom/'..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if finished or n==4200 then out:close();emu.stop(0)end
end,emu.eventType.endFrame)
