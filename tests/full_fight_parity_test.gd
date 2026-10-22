extends SceneTree
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons() -> int:return sample
func _initialize() -> void:
 var failures:=0
 var report: Array=[]
 for case in ["full_fight"]:
  var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_"+case+".bin")
  var stride:=4110
  if raw.is_empty() or raw.size()%stride!=0:push_error("Missing/incomplete coupled capture");quit(1);return
  if raw.decode_u32(0)!=2018 or raw.size()/stride<4959:push_error("Capture must begin at the first controllable frame and reach the result");quit(1);return
  var fight=Adapter.new();fight.start();var a=fight.animation
  for i in 2048:a.m[i]=raw[4+i]
  a.m[0x1e]=(a.m[0x1e]-1)&255
  fight.hp=a.m[0x391];fight.opponent_hp=a.m[0x398];fight._sync_resources()
  var checked: Array=[5,0x18,0x19,0x1e,0x61,0xa1,0xb0,0xb1,0x301,0x302,0x304,0x305,0x306,0x311,0x391,0x398,0x4fd,0x4fe,0x4ff,0x581,0,0xd0,0xd2,0xd3,0xd4,0xd5,0xd6,0xd7,0xd8,0xd9]
  for span in [[0x40,0x47],[0x50,0x5c],[0x70,0x7a],[0x90,0x9c],[0xb4,0xd0],[0x321,0x348],[0x3e8,0x3ee]]:
   for address in range(span[0],span[1]):
    if address!=0x325 and not checked.has(address):checked.append(address)
  # $325 is a PPU hearts-strip upload flag; no source graphics are rendered.
  var mismatch:=0;var calls:=0;var contacts:=0
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
   fight.step();calls+=1
   if not a.error.is_empty():push_error(a.error);quit(1);return
   var post:=off+stride-2048
   for address in checked:
    if a.m[address]!=raw[post+address]:
     mismatch+=1
     if mismatch<8:print(case," ",frame," %04X got %d expected %d" % [address,a.m[address],raw[post+address]])
     break
  contacts=events.filter(func(e):return e.kind in ["hit","counter","hurt","guard","evade","blocked","miss"]).size()
  var terminal:=int(raw[raw.size()-2048])
  if terminal!=252 or fight.result!="win" or fight.verdict!="TKO" or a.m[0x3d1]!=3:failures+=1;push_error("Capture must cover three knockdowns through TKO")
  report.append({"terminal":terminal,"result":fight.result,"verdict":fight.verdict,"opponent_downs":a.m[0x3d1],"events":events,"case":case,"frames":calls,"first_frame":raw.decode_u32(0),"last_frame":previous,"contacts":contacts,"checked_addresses":checked.size(),"mismatching_frames":mismatch})
  print("COUPLED ",case,": ",calls," consecutive frames, ",contacts," contacts, ",mismatch," mismatching frames")
  failures+=mismatch
  fight.event.disconnect(on_event)
 var out=FileAccess.open("res://research/evidence/animation/full_fight_validation.json",FileAccess.WRITE)
 out.store_string(JSON.stringify({"scope":"Production fight adapter, one initial RAM seed, stable raw button samples only. Recovered edge polling runs locally. Covers first controllable frame through three-knockdown TKO. Checks 143 gameplay/animation fields; excludes serial hardware sampling, entrance, inter-round setup and full PPU output.","runs":report},"  "))
 quit(1 if failures else 0)
