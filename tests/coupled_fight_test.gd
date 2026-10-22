extends SceneTree
const Machine=preload("res://scripts/recovered/animation_machine.gd")
const RNG=preload("res://scripts/recovered/nes_animation_rng.gd")
func _initialize() -> void:
 var failures:=0
 var report: Array=[]
 for case in ["idle","punches"]:
  var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_"+case+".bin")
  var stride:=4100 if case=="idle" else 4110
  if raw.is_empty() or raw.size()%stride!=0:push_error("Missing/incomplete coupled capture");quit(1);return
  var a=Machine.new();a.fight_control_enabled=true
  for i in 2048:a.m[i]=raw[4+i]
  a.m[0x1e]=(a.m[0x1e]-1)&255
  var checked: Array=[5,0x18,0x19,0x1e,0x61,0xa1,0xb0,0xb1,0x301,0x302,0x304,0x305,0x306,0x311,0x391,0x398,0x4fd,0x4fe,0x4ff,0x581]
  for span in [[0x40,0x47],[0x50,0x5c],[0x70,0x7a],[0x90,0x9c],[0xb4,0xd0],[0x321,0x348],[0x3e8,0x3ee]]:
   for address in range(span[0],span[1]):
    if address!=0x325 and not checked.has(address):checked.append(address)
  # $325 is a PPU hearts-strip upload flag; no source graphics are rendered.
  var mismatch:=0;var calls:=0;var contacts:=0
  var previous:=int(raw.decode_u32(0))-1
  for off in range(0,raw.size(),stride):
   var frame:=int(raw.decode_u32(off))
   if frame!=previous+1:push_error("Non-contiguous source capture");quit(1);return
   previous=frame
   var random_value=RNG.advance((a.m[0x1e]+1)&255,a.m[0xd0],a.m[0x19])
   a.m[0x18]=random_value.x;a.m[0x19]=random_value.y
   if case=="punches":
    # Only controller-poll outputs cross this boundary; no combat state reseed.
    for i in 10:a.m[0xd0+i]=raw[off+2052+i]
   a.tick(true)
   if (a.m[0x58]|a.m[0x98])&128:contacts+=1
   a.control(0x805d);a.finish_tick();calls+=1
   if not a.error.is_empty():push_error(a.error);quit(1);return
   var post:=off+stride-2048
   for address in checked:
    if a.m[address]!=raw[post+address]:
     mismatch+=1
     if mismatch<8:print(case," ",frame," %04X got %d expected %d" % [address,a.m[address],raw[post+address]])
     break
  report.append({"case":case,"frames":calls,"first_frame":raw.decode_u32(0),"last_frame":previous,"contacts":contacts,"checked_addresses":checked.size(),"mismatching_frames":mismatch})
  print("COUPLED ",case,": ",calls," consecutive frames, ",contacts," contacts, ",mismatch," mismatching frames")
  failures+=mismatch
 var out=FileAccess.open("res://research/evidence/animation/coupled_validation.json",FileAccess.WRITE)
 out.store_string(JSON.stringify({"scope":"One initial RAM seed, continuous simulation. Punch case injects captured controller-poll outputs only. Checks gameplay/animation fields, not all RAM or original PPU output.","runs":report},"  "))
 quit(1 if failures else 0)
