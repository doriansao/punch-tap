local root='G:/Programming/punch-tap/research/evidence/animation/normal_knockdowns/full/'
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
local function input()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
 emu.setInput(b,0)
end
emu.addEventCallback(input,emu.eventType.inputPolled)


local files={}
local function capture(name,address,prg)
 local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/normal_knockdowns_'..name..'.bin','wb'));files[#files+1]=out
 local pending=nil;local installed={}
 local function dump() local b={};for a=0,2047 do b[#b+1]=string.char(r(a)) end;return table.concat(b) end
 emu.addMemoryCallback(function()
  if r(0x90)~=64 or pending then return end
  if prg and emu.convertAddress(address,emu.memType.nesMemory).address~=prg then return end
  local st=emu.getState();local sp=st['cpu.sp'];local ret=(r(0x100+((sp+1)%256))+256*r(0x100+((sp+2)%256))+1)%65536
  pending={ram=dump(),ret=ret,frame=n+1}
  if not installed[ret]then installed[ret]=true;emu.addMemoryCallback(function()
   if pending and pending.ret==ret then out:write(string.pack('<I4',pending.frame),pending.ram,dump());pending=nil end
  end,emu.callbackType.exec,ret)end
 end,emu.callbackType.exec,address)
end
capture('entrance_opponent_step',0xC4E7,nil)
capture('entrance_compositor',0xC890,nil)
emu.addEventCallback(function() n=n+1;if n==2018 then for _,out in ipairs(files)do out:close()end;emu.stop(0)end end,emu.eventType.endFrame)
