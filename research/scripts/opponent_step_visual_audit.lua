local root='G:/Programming/punch-tap/research/evidence/animation/visual_audit/full/'
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
emu.addEventCallback(function()
 local b={a=false,b=false,start=n>=150 and n<1900 and n%120<4,select=false,up=false,down=false,left=false,right=false}
 if n>=2300 and n<2303 then b.a=true end
 if n>=2400 and n<2403 then b.b=true end
 if n>=2500 and n<2503 then b.a=true;b.up=true end
 if n>=2600 and n<2603 then b.b=true;b.up=true end
 if n>=2700 and n<2703 then b.left=true end
 if n>=2800 and n<2803 then b.right=true end
 if n>=2990 and n<3030 then b.down=true end
 emu.setInput(b,0)
end,emu.eventType.inputPolled)

local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/visual_audit_opponent_step.bin','wb'))
local pending=nil
local installed={}
local function dump()
 local b={};for a=0,2047 do b[#b+1]=string.char(r(a)) end;return table.concat(b)
end
emu.addMemoryCallback(function()
 if n<2295 or pending then return end
 
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
end,emu.callbackType.exec,0xC4E7)
emu.addEventCallback(function()
 n=n+1;if n==3400 then out:close();emu.stop(0) end
end,emu.eventType.endFrame)
