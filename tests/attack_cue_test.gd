extends SceneTree
class Preview extends "res://scripts/main.gd":
 var cues: Array=[]
 func _notification(_what: int) -> void:pass
 func play_tone(frequency: float,_duration: float,_volume: float) -> void:
  if frequency==520.0:cues.append({"tick":fight.ticks,"pose":fight.animation.current("opponent").get("visual_pose_id",-1)})
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons() -> int:return sample
func _initialize() -> void:call_deferred("run_checks")
func run_checks() -> void:
 var game=Preview.new();game.fight=Adapter.new();root.add_child(game)
 game.set_process(false);game.set_physics_process(false);game._start_or_resume()
 var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_defense_fight.bin")
 if raw.size()!=2183*4110:push_error("Missing defense fixture");quit(1);return
 var a=game.fight.animation
 for i in 2048:a.m[i]=raw[4+i]
 a.m[0x1e]=(a.m[0x1e]-1)&255
 for off in range(0,raw.size(),4110):
  game.fight.sample=raw[off+2052];game.fight.step();game._process(1.0/60.0)
 if game.cues.size()!=6:push_error("Expected one cue for each of six jabs");quit(1);return
 if game.cues[0].tick+2017!=2974:push_error("First visible windup must start on source frame 2974");quit(1);return
 for cue in game.cues:
  if int(cue.pose)!=12:push_error("Attack sound played before visible windup");quit(1);return
 game.queue_free();await process_frame
 print("ATTACK CUES: six jabs, once per displayed windup; first cue frame 2974")
 quit()
