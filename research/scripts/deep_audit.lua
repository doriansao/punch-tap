local root='G:/Programming/punch-tap/research/evidence/'
local case='deep_audit'
local f=assert(io.open(root..case..'.csv','w'))
local w=assert(io.open(root..case..'_writes.csv','w'))
f:write('frame,relative,action,state_0090,sequence_cursor_00a5,timer,next,hearts,stars,hp,joe_hp,raw_0096,raw_009a\n')
w:write('frame,address,value,pc,prg_offset,a,x,y\n')
local ram=assert(io.open(root..case..'_ram.bin','wb'))
local n=0
local function r(a) return emu.read(a,emu.memType.nesDebug) end
local function input()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
 emu.setInput(b,0)
end
emu.addEventCallback(input,emu.eventType.inputPolled)
emu.addMemoryCallback(function()
 if n>2800 and n<3000 then
  local p=emu.convertAddress(0x8335,emu.memType.nesMemory)
  if p.address==0xE335 then local q=io.open(root..'knockout_condition.txt','a');q:write(string.format('frame=%d pc=8335 prg=E335 BA=%d HP=%d player_contact=%d\n',n,r(0xBA),r(0x398),r(0x58)));q:close() end
 end
end,emu.callbackType.exec,0x8335)


local audit=assert(io.open(root..'deep_audit_events.csv','w'))
audit:write('frame,pc,prg,a,x,y,player,opponent,hp,joe_hp,display_hp,stars,hearts,ba,e0,e1,e2,damage_bonus,clock,round,count0,count1,count2,count3,count4\n')
for _,pc in ipairs({0x8505,0x83C5,0x89DE,0xB2EB,0xB1A7,0xC550}) do
 emu.addMemoryCallback(function()
  if n<2295 then return end
  local s=emu.getState();local p=emu.convertAddress(pc,emu.memType.nesMemory)
  if pc<0xA000 and p.address~=pc+0x6000 then return end
  local row={n,string.format('%04X',pc),string.format('%X',p.address),s['cpu.a'],s['cpu.x'],s['cpu.y']}
  for _,a in ipairs({0x50,0x90,0x391,0x398,0x399,0x342,0x347,0xBA,0xE0,0xE1,0xE2,0x5D3,0x306,0x30B,0xC0,0xC1,0xC2,0xC3,0xC4}) do row[#row+1]=r(a) end
  audit:write(table.concat(row,',')..'\n')
 end,emu.callbackType.exec,pc)
end

local addresses={0x341,0x343,0xBC,0xC0,0xC4,0x3CA,0x8F,0xBA,0x50,0x05,0x300,0x30B,0x90,0xA5,0x39,0x3A,0x347,0x342,0x391,0x398}
for _,a in ipairs(addresses) do
 emu.addMemoryCallback(function(addr,val)
  if n>=2295 then local s=emu.getState();local p=emu.convertAddress(s['cpu.pc'],emu.memType.nesMemory)
   w:write(string.format('%d,%04X,%d,%04X,%X,%d,%d,%d\n',n,addr,val,s['cpu.pc'],p.address,s['cpu.a'],s['cpu.x'],s['cpu.y'])) end
 end,emu.callbackType.write,a)
end
emu.addEventCallback(function()
 n=n+1
 if n>=2295 then
  
  f:write(string.format('%d,%d,%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n',n,n-2300,case,r(0x90),r(0xA5),r(0x39),r(0x3A),r(0x347),r(0x342),r(0x391),r(0x398),r(0x96),r(0x9A)))
 end
 if n%500==0 then
  local p=io.open(root..case..'_'..n..'.png','wb');p:write(emu.takeScreenshot());p:close()
  local o=io.open(root..case..'_'..n..'_oam.bin','wb');for a=0,255 do o:write(string.char(emu.read(a,emu.memType.nesSpriteRam))) end;o:close()
  local t=io.open(root..case..'_'..n..'_nametable.bin','wb');for a=0,2047 do t:write(string.char(emu.read(a,emu.memType.nesNametableRam))) end;t:close()
 end
 if n==7200 then f:close();w:close();ram:close();audit:close();emu.stop(0) end
end,emu.eventType.endFrame)
