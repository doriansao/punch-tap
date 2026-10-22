local n=0
local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/fight_start_ram.bin','wb'))
local function r(a)return emu.read(a,emu.memType.nesDebug)end
emu.addEventCallback(function()emu.setInput({a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false},0)end,emu.eventType.inputPolled)
emu.addEventCallback(function()
 n=n+1
 if n>=1500 then local b={};for a=0,2047 do b[#b+1]=string.char(r(a))end;out:write(string.pack('<I4',n),table.concat(b))end
 if n==2400 then out:close();emu.stop(0)end
end,emu.eventType.endFrame)
