local root='G:/Programming/punch-tap/research/evidence/'
local f=assert(io.open(root..'boot.csv','w'))
f:write('frame,round,active,player_hp,opponent_hp,player_pose,opponent_pose\n')
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
emu.addEventCallback(function()
 emu.setInput({a=false,b=false,select=false,start=n>=150 and n%120<4,up=false,down=false,left=false,right=false},0)
end,emu.eventType.inputPolled)
emu.addEventCallback(function()
 n=n+1
 f:write(string.format('%d,%d,%d,%d,%d,%d,%d\n',n,r(0x30B),r(0x300),r(0x391),r(0x398),r(0x90),r(0xA5)))
 if n%500==0 then local p=io.open(root..'boot_'..n..'.png','wb');p:write(emu.takeScreenshot());p:close() end
 if n==3500 then f:close();emu.stop(0) end
end,emu.eventType.endFrame)
