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

local log=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/normal_knockdowns_commands.csv','w'))
log:write('frame,actor,script,cursor,opcode,operands,pose,x_or_scroll,y\n')
local function command(actor,ptr,cursor,pose,x,y)
 if n<2295 then return end
 local address=r(ptr)+256*r(ptr+1);local c=r(cursor);local bytes={}
 for k=1,6 do bytes[#bytes+1]=string.format('%02X',r(address+c+k)) end
 log:write(string.format('%d,%s,%04X,%d,%02X,%s,%d,%d,%d\n',n+1,actor,address,c,r(address+c),table.concat(bytes,' '),r(pose),r(x),r(y)))
end
emu.addMemoryCallback(function()
 local p=emu.convertAddress(0x8325,emu.memType.nesMemory)
 if p.address==0x16325 then command('player',0x54,0x53,0x61,0x15,0x71) end
end,emu.callbackType.exec,0x8325)
emu.addMemoryCallback(function() command('opponent',0x94,0x93,0xA1,0xB0,0xB1) end,emu.callbackType.exec,0xC550)
emu.addEventCallback(function()
 n=n+1
 if n==7200 then log:close();emu.stop(0) end
end,emu.eventType.endFrame)
