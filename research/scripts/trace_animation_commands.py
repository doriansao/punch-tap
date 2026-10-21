from pathlib import Path
root=Path(__file__).resolve().parents[1]
for case,end in [('visual_audit',3400),('normal_knockdowns',7200),('player_getup_wide',4550)]:
 src=(root/'scripts'/f'anim_{case}_full.lua').read_text()
 src=src[:src.index('local ram=')]
 src+=rf'''
local log=assert(io.open('{(root/'evidence/animation').as_posix()}/{case}_commands.csv','w'))
log:write('frame,actor,script,cursor,opcode,operands,pose,x_or_scroll,y\n')
local function command(actor,ptr,cursor,pose,x,y)
 if n<2295 then return end
 local address=r(ptr)+256*r(ptr+1);local c=r(cursor);local bytes={{}}
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
 if n=={end} then log:close();emu.stop(0) end
end,emu.eventType.endFrame)
'''
 (root/'scripts'/f'commands_{case}.lua').write_text(src)
print('Prepared live bytecode-dispatch tracing')
