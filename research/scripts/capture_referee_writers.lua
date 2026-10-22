-- Trace actual referee/count signalling writers without changing ROM RAM.
local n=0
local seen={}
local log=assert(io.open('G:/Programming/punch-tap/research/evidence/animation/referee_writers.txt','w'))
local function r(a)return emu.read(a,emu.memType.nesDebug)end
emu.addEventCallback(function()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
 emu.setInput(b,0)
end,emu.eventType.inputPolled)

local addresses={0x1b,0xbb}
for a=0x30,0x3f do addresses[#addresses+1]=a end
for _,address in ipairs(addresses)do
 emu.addMemoryCallback(function(a,v)
  if n<1100 then return end
  local pc=emu.getState()['cpu.pc'];local prg=emu.convertAddress(pc,emu.memType.nesMemory).address
  local key=string.format('%04X pc=%04X prg=%05X',a,pc,prg)
  if not seen[key]then seen[key]=true;log:write(n..' '..key..' value='..v..'\n');log:flush()end
 end,emu.callbackType.write,address)
end
emu.addEventCallback(function()n=n+1;if n==7100 then log:close();emu.stop(0)end end,emu.eventType.endFrame)
