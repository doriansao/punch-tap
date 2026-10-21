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

local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/normal_knockdowns_opponent_vm.bin','wb'))
local pending=nil
local installed={}
local function dump()
 local b={};for a=0,2047 do b[#b+1]=string.char(r(a)) end;return table.concat(b)
end
emu.addMemoryCallback(function()
 if n<2295 then return end
 if pending then out:write(string.pack('<I4',pending.frame),pending.ram,dump());pending=nil end
 
 local s=emu.getState();local sp=s['cpu.sp']
 local ret=(r(0x100+((sp+1)%256))+256*r(0x100+((sp+2)%256))+1)%65536
 pending={ram=dump(),ret=ret,frame=n+1}
 if not installed[ret] then
  installed[ret]=true
  emu.addMemoryCallback(function()
   if pending and pending.ret==ret then
    out:write(string.pack('<I4',pending.frame),pending.ram,dump());pending=nil
   end
  end,emu.callbackType.exec,ret)
 end
end,emu.callbackType.exec,0xC550)
emu.addEventCallback(function()
 n=n+1;if n==7200 then out:close();emu.stop(0) end
end,emu.eventType.endFrame)
