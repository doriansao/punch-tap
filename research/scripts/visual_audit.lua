-- Cold-boot, ordinary-input visual trace. No memory patches.
local root='G:/Programming/punch-tap/research/evidence/visual_audit/'
local log=assert(io.open(root..'frames.csv','w'))
log:write('frame,player_state,player_timer,player_cursor,player_script,contact,opponent_state,opponent_timer,opponent_cursor,opponent_script,sprite_cursor\n')
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
emu.addEventCallback(function()
 n=n+1
 if n>=2295 then
  log:write(string.format('%d,%d,%d,%d,%04X,%d,%d,%d,%d,%04X,%d\n',n,r(0x50),r(0x52),r(0x53),r(0x54)+256*r(0x55),r(0x58),r(0x90),r(0x92),r(0x93),r(0x94)+256*r(0x95),r(0xA5)))
  local f=assert(io.open(root..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n==3400 then log:close();emu.stop(0) end
end,emu.eventType.endFrame)
