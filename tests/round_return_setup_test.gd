extends SceneTree
func _initialize():
 var old=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_body_counter_fight.bin")
 var next=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_round2_fight.bin")
 var fight=load("res://scripts/fight_model_vm.gd").new();fight.start()
 for i in 2048:fight.animation.m[i]=old[old.size()-2048+i]
 fight.hp=fight.animation.m[0x391];fight.opponent_hp=fight.animation.m[0x398];fight._sync_resources()
 fight._next_round()
 var checked:Array=[0,5,6,0x15,0xb0,0xb1,0x300,0x301,0x302,0x304,0x305,0x306,0x311,0x391,0x397,0x398,0x39e,0x4fd,0x4fe,0x4ff,0x581]
 for span in [[0x40,0x47],[0x50,0x5c],[0x70,0x7a],[0x90,0x9c],[0xb4,0xd0],[0x321,0x348],[0x3e8,0x3ee]]:
  for address in range(span[0],span[1]):
   if address!=0x325 and not checked.has(address):checked.append(address)
 var failures:=0
 for address in checked:
  if fight.animation.m[address]!=next[4+address]:
   failures+=1;print("ROUND SETUP %04X got %d expected %d" % [address,fight.animation.m[address],next[4+address]])
 print("ROUND SETUP: ",checked.size()," logical fields, ",failures," mismatches; excludes corner RNG/time and PPU transfers")
 var speech:Array=[];var visible:Array=[]
 for tick in 600:
  fight.step()
  if fight.animation.current("referee").get("speech","")=="FIGHT!":speech.append(tick)
  if fight.round_scene_visible:visible.append(tick)
 if not fight.animation_failure.is_empty() or speech.size()!=23 or speech[0]!=367 or speech[-1]!=389 or visible[0]!=4 or fight.round_centis<=0:
  failures+=1;push_error("Production corner continuation failed visibility / FIGHT / live clock handoff")
 print("ROUND RETURN live continuation: FIGHT ",speech,"; first visible tick ",visible[0],"; clock ",fight.round_centis)
 quit(1 if failures else 0)
