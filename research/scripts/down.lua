local root='G:/Programming/punch-tap/research/evidence/'
local case='down'
local f=assert(io.open(root..case..'.csv','w'))
local w=assert(io.open(root..case..'_writes.csv','w'))
f:write('frame,relative,action,state_0090,sequence_cursor_00a5,timer,next,hearts,stars,hp,joe_hp,raw_0096,raw_009a\n')
w:write('frame,address,value,pc,prg_offset,a,x,y\n')
local ram=assert(io.open(root..case..'_ram.bin','wb'))
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
local function input()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and n<2300+3 then b.down=true end
 emu.setInput(b,0)
end
emu.addEventCallback(input,emu.eventType.inputPolled)
local addresses={0x90,0xA5,0x39,0x3A,0x347,0x342,0x391,0x398}
for _,a in ipairs(addresses) do
 emu.addMemoryCallback(function(addr,val)
  if n>=2295 then local s=emu.getState();local p=emu.convertAddress(s['cpu.pc'],emu.memType.nesMemory)
   w:write(string.format('%d,%04X,%d,%04X,%X,%d,%d,%d\n',n,addr,val,s['cpu.pc'],p.address,s['cpu.a'],s['cpu.x'],s['cpu.y'])) end
 end,emu.callbackType.write,a)
end
emu.addEventCallback(function()
 n=n+1
 if n>=2295 then
  local bytes={};for a=0,2047 do bytes[#bytes+1]=string.char(r(a)) end;ram:write(table.concat(bytes))
  f:write(string.format('%d,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',n,n-2300,case,r(0x90),r(0xA5),r(0x39),r(0x3A),r(0x347),r(0x342),r(0x391),r(0x398),r(0x96),r(0x9A)))
 end
 if n==2300 or n==2310 or n==2320 then
  local p=io.open(root..case..'_'..n..'.png','wb');p:write(emu.takeScreenshot());p:close()
  local o=io.open(root..case..'_'..n..'_oam.bin','wb');for a=0,255 do o:write(string.char(emu.read(a,emu.memType.nesSpriteRam))) end;o:close()
  local t=io.open(root..case..'_'..n..'_nametable.bin','wb');for a=0,2047 do t:write(string.char(emu.read(a,emu.memType.nesNametableRam))) end;t:close()
 end
 if n==2600 then f:close();w:close();ram:close();emu.stop(0) end
end,emu.eventType.endFrame)
