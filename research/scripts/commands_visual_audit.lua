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

local log=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/visual_audit_commands.csv','w'))
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
 if n==3400 then log:close();emu.stop(0) end
end,emu.eventType.endFrame)
