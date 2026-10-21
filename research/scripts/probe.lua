local f=assert(io.open('G:/Programming/punch-tap/research/evidence/state.txt','w'))
for k,v in pairs(emu.getState()) do f:write(k..'='..tostring(v)..'\n') end
for k,v in pairs(emu.getInput(0)) do f:write('INPUT '..k..'='..tostring(v)..'\n') end
f:close()
emu.addEventCallback(function() emu.stop(0) end,emu.eventType.endFrame)
