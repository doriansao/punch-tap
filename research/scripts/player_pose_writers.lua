local root='G:/Programming/punch-tap/research/evidence/animation/player_getup_wide/full/'
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
local function input()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=4000 then if n%16<3 then b.a=true elseif n%16>=8 and n%16<11 then b.b=true end end
 emu.setInput(b,0)
end
emu.addEventCallback(input,emu.eventType.inputPolled)


local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/player_pose_writers.csv','w'))
out:write('frame,pc,prg,pose,state,cursor,timer,scroll\n')
emu.addMemoryCallback(function(addr,value)
 if n>=4200 then local st=emu.getState();local pc=st['cpu.pc'];local p=emu.convertAddress(pc,emu.memType.nesMemory);out:write(string.format('%d,%04X,%X,%d,%d,%d,%d,%d\n',n+1,pc,p.address,value,r(0x50),r(0x53),r(0x52),r(0x15))) end
end,emu.callbackType.write,0x61)
emu.addEventCallback(function() n=n+1;if n==4550 then out:close();emu.stop(0) end end,emu.eventType.endFrame)
