local n=0
local function r(a)return emu.read(a,emu.memType.nesDebug)end
emu.addEventCallback(function()
 local b={a=false,b=false,select=false,start=n>=150 and n<1900 and n%120<4,up=false,down=false,left=false,right=false}
 if n>=2300 and r(0x90)~=25 and r(0xBA)==0 then local t=n-2300;if t%50<3 then
 if r(0x342)>0 then b.start=true else b.up=true;if math.floor(t/50)%2==0 then b.a=true else b.b=true end end end end
 emu.setInput(b,0)
end,emu.eventType.inputPolled)
emu.addEventCallback(function()
 n=n+1
 local selected=false
 for _,impact in ipairs({2312,2362,2962,3162,3412,4162,4539}) do
  if n>=impact-3 and n<=impact+5 then selected=true end
 end
 if selected then
  local f=assert(io.open('G:/Programming/punch-tap/research/evidence/contact_audit/rom/'..n..'.png','wb'));f:write(emu.takeScreenshot());f:close()
 end
 if n==4545 then emu.stop(0)end
end,emu.eventType.endFrame)
