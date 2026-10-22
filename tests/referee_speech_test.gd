extends SceneTree
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons()->int:return sample
func _initialize():call_deferred("run")
func run():
 var seen: Dictionary={};var checked:=0
 var game=load("res://scripts/main.gd").new();game.fight=Adapter.new();root.add_child(game)
 game.sound_on=false;game.set_physics_process(false);game.set_process(false)
 var capture:=OS.get_cmdline_user_args().has("--capture")
 for fixture in ["full","body"]:
  game._start_or_resume()
  var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_"+fixture+"_fight.bin")
  var a=game.fight.animation
  for i in 2048:a.m[i]=raw[4+i]
  a.m[0x1e]=(a.m[0x1e]-1)&255
  var queue: Array=["",""];var speech:=""
  for off in range(0,raw.size(),4110):
   var post:=off+2062;var pose:=int(raw[post+0x61])
   if raw[post+0x60]!=0:
    if pose in [128,150,151,153]:speech=""
    elif pose>=154 and pose<=163:speech=str(pose-153)
    elif pose in [166,168,169]:speech={166:"FIGHT!",168:"KO!",169:"TKO!"}[pose]
   queue.append(speech);var expected: String=queue.pop_front()
   game.fight.sample=raw[off+2052];game.fight.step();game._process(1.0/60)
   var actual: Dictionary=a.current("referee")
   if not actual.is_empty():
    assert(actual.speech==expected,"Speech command queue mismatch at "+str(raw.decode_u32(off)))
    if not expected.is_empty() and not seen.has(expected):
     seen[expected]=int(raw.decode_u32(off))
     if capture and expected in ["1","KO!","TKO!"]:
      game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
      root.get_texture().get_image().save_png("res://research/evidence/presentation/speech_"+expected.replace("!","")+".png")
   checked+=1
 assert(seen.has("1") and seen.has("10") and seen.has("KO!") and seen.has("TKO!"),"Count/KO/TKO fixtures required")
 print("REFEREE SPEECH: ",checked," ROM frames; ",seen)
 game.queue_free();await process_frame;quit()
