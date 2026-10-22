extends SceneTree
class Preview extends "res://scripts/main.gd":
 func _notification(_what: int) -> void:pass
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons() -> int:return sample
func _initialize() -> void:call_deferred("run_checks")
func run_checks() -> void:
 var game=Preview.new();game.fight=Adapter.new();root.add_child(game)
 game.sound_on=false;game.set_process(false);game.set_physics_process(false);game._start_or_resume()
 var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_full_fight.bin")
 if raw.size()!=4959*4110:push_error("Missing full fight fixture");quit(1);return
 var a=game.fight.animation
 for i in 2048:a.m[i]=raw[4+i]
 a.m[0x1e]=(a.m[0x1e]-1)&255
 var checked:=0
 for off in range(0,raw.size(),4110):
  var frame:=int(raw.decode_u32(off))
  var before:=int(game.fight.hp)
  game.fight.sample=raw[off+2052];game.fight.step();game._process(1.0/60.0)
  if frame in [4539,5840]:
   if game.fight.hp!=before-11 or game.hit_flash!=0 or int(a.current("opponent").art_frame)!=8:
    push_error("Damage must resolve on source tick without flashing the windup");quit(1);return
   checked+=1
  if frame in [4540,5841]:
   if game.hit_flash<=0 or int(a.current("opponent").art_frame)!=9:
    push_error("Damage presentation must coincide with the displayed strike");quit(1);return
   checked+=1
 if checked!=4:push_error("Incoming contacts not covered");quit(1);return
 game.queue_free();await process_frame
 print("IMPACT PRESENTATION: both captured incoming contacts preserve damage tick and flash on displayed strike")
 quit()
