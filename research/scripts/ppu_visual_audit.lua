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

local out=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/visual_audit_ppu.bin','wb'))
local log=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/visual_audit_ppu.csv','w'))
log:write('frame,update_pose,destination,stream,scroll,left0,left1,right0,right1,large,split_scroll\n')
local pose,dest,stream=0,0,0
local split_scroll=0
emu.addMemoryCallback(function() split_scroll=emu.getState()['cpu.x'] end,emu.callbackType.exec,0xA0C5)
emu.addMemoryCallback(function()
 if emu.convertAddress(0x8020,emu.memType.nesMemory).address==0x16020 then
  pose=r(0x61);dest=r(0x63)+256*r(0x64);stream=r(0x66)+256*r(0x67)
 end
end,emu.callbackType.exec,0x8020)
emu.addEventCallback(function()
 n=n+1
 if n>=2295 then
  local bytes={}
  for a=0x2000,0x2fff do bytes[#bytes+1]=string.char(emu.read(a,emu.memType.nesPpuDebug)) end
  for a=0x3f00,0x3f1f do bytes[#bytes+1]=string.char(emu.read(a,emu.memType.nesPpuDebug)) end
  for a=0,255 do bytes[#bytes+1]=string.char(emu.read(a,emu.memType.nesSpriteRam)) end
  out:write(table.concat(bytes))
  local s=emu.getState()
  log:write(string.format('%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',n,pose,dest,stream,r(0x15),s['mapper.leftChrPage[0]'],s['mapper.leftChrPage[1]'],s['mapper.rightChrPage[0]'],s['mapper.rightChrPage[1]'],s['ppu.control.largeSprites'] and 1 or 0,split_scroll))
 end
 if n==3400 then out:close();log:close();emu.stop(0) end
end,emu.eventType.endFrame)
