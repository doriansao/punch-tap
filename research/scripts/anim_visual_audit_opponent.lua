local root='G:/Programming/punch-tap/research/evidence/animation/visual_audit/opponent/'
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
local ram=assert(io.open(root..'ram.bin','wb'))
emu.addEventCallback(function()
 n=n+1
 if n>=2295 then
  local bytes={};for a=0,2047 do bytes[#bytes+1]=string.char(r(a)) end;ram:write(table.concat(bytes))
  local f=assert(io.open(root..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n==3400 then ram:close();emu.stop(0) end
end,emu.eventType.endFrame)
