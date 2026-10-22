extends SceneTree
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons() -> int:return sample
func _initialize() -> void:
 var failures:=0
 var report: Array=[]
 for case in ["body_counter_fight"]:
  var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_"+case+".bin")
  var stride:=4110
  if raw.is_empty() or raw.size()%stride!=0:push_error("Missing/incomplete coupled capture");quit(1);return
  if raw.decode_u32(0)!=2018 or raw.size()/stride<3708:push_error("Capture must begin at the first controllable frame and cover the complete counter experiment");quit(1);return
  var fight=Adapter.new();fight.start();var a=fight.animation
  for i in 2048:a.m[i]=raw[4+i]
  a.m[0x1e]=(a.m[0x1e]-1)&255
  fight.hp=a.m[0x391];fight.opponent_hp=a.m[0x398];fight._sync_resources()
  var checked: Array=[5,0x18,0x19,0x1e,0x61,0xa1,0xb0,0xb1,0x301,0x302,0x304,0x305,0x306,0x311,0x391,0x398,0x4fd,0x4fe,0x4ff,0x581,0x9c,0x493,0x497,0x49b,0x49f,0,0xd0,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9]
  for span in [[0x40,0x47],[0x50,0x5c],[0x70,0x7a],[0x90,0x9c],[0xb4,0xd0],[0x321,0x348],[0x3e8,0x3ee]]:
   for address in range(span[0],span[1]):
    if address!=0x325 and not checked.has(address):checked.append(address)
  # $325 is a PPU hearts-strip upload flag; no source graphics are rendered.
  var mismatch:=0;var calls:=0;var contacts:=0;var body_hits:=0;var crosses:=0;var previous_state:=0
  var events: Array=[]
  var on_event=func(kind,detail):
   if kind in ["hit","hurt","guard","evade","miss","blocked","counter","knockdown","getup"]:events.append({"frame":2017+fight.ticks,"kind":kind,"detail":detail})
  fight.event.connect(on_event)
  var previous:=int(raw.decode_u32(0))-1
  for off in range(0,raw.size(),stride):
   var frame:=int(raw.decode_u32(off))

   if frame!=previous+1:push_error("Non-contiguous source capture");quit(1);return
   previous=frame
   fight.sample=raw[off+2052]
   var old_hp: int=fight.opponent_hp
   fight.step();calls+=1
   if fight.opponent_hp<old_hp:body_hits+=1
   if (a.m[0x90]&127)==22 and previous_state!=22:crosses+=1
   previous_state=a.m[0x90]&127
   if not a.error.is_empty():push_error(a.error);quit(1);return
   var post:=off+stride-2048
   for address in checked:
    if a.m[address]!=raw[post+address]:
     mismatch+=1
     if mismatch<8:print(case," ",frame," %04X got %d expected %d" % [address,a.m[address],raw[post+address]])
     break
  contacts=events.filter(func(e):return e.kind in ["hit","counter","hurt","guard","evade","blocked","miss"]).size()
  var terminal:=int(a.m[0])
  if body_hits!=4 or crosses!=3 or a.m[0x301]!=129:failures+=1;push_error("Need four successful body counters and three state-22 attacks")
  report.append({"body_hits":body_hits,"state22_entries":crosses,"terminal":terminal,"result":fight.result,"verdict":fight.verdict,"opponent_downs":a.m[0x3d1],"events":events,"case":case,"frames":calls,"first_frame":raw.decode_u32(0),"last_frame":previous,"contacts":contacts,"checked_addresses":checked.size(),"mismatching_frames":mismatch})
  print("COUPLED ",case,": ",calls," consecutive frames, ",contacts," contacts, ",mismatch," mismatching frames")
  failures+=mismatch
  fight.event.disconnect(on_event)
  # Adapted corner input is a smoke check, separate from the ROM parity claim.
  if fight.state!="between_rounds" or not fight.act("body","left"):
   failures+=1;push_error("Completed bell transition must allow corner continuation")
  if fight.post_bell_started or fight.round_fade!=0 or fight.round_number!=2 or fight.queued_buttons!=0:
   failures+=1;push_error("Corner continuation retained fade or queued an accidental punch")
  if not a.current("player").box.is_empty():failures+=1;push_error("Next round retained stale presentation")
 var out=FileAccess.open("res://research/evidence/animation/body_counter_validation.json",FileAccess.WRITE)
 out.store_string(JSON.stringify({"scope":"Production fight adapter, one initial RAM seed, stable raw button samples only. Recovered edge polling runs locally. Covers four successful body counters and three state-22 attacks through source post-bell dispatch and fade frame 5903. Checks 148 gameplay/animation fields; excludes serial hardware sampling, entrance, inter-round setup and full PPU output.","runs":report},"  "))
 quit(1 if failures else 0)
