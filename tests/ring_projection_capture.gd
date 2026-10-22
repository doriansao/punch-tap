extends SceneTree
class Preview extends "res://scripts/main.gd":
 func toggle_pause() -> void:pass
 func _input(_event:InputEvent) -> void:pass
 func _notification(_what: int) -> void:pass
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons()->int:return sample
func _initialize():call_deferred("capture")
func capture():
 root.size=Vector2i(540,960)
 var clips: Array=JSON.parse_string(FileAccess.get_file_as_string("res://research/scripts/motion_audit_clips.json"))
 var game=Preview.new();game.fight=Adapter.new();root.add_child(game)
 for control in game.find_children("*","Control",true,false):control.tooltip_text=""
 game.sound_on=false;game.set_physics_process(false);game.set_process(false);game._update_buttons()
 var frames: Array=[];var trace: Array=[]
 var args:=OS.get_cmdline_user_args()
 var fixtures: Array=["full","round2"] if args.is_empty() else [args[0]]
 for fixture in fixtures:
  game.mode="intro";game._start_or_resume()
  var raw=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_"+fixture+"_fight.bin")
  var a=game.fight.animation
  for i in 2048:a.m[i]=raw[4+i]
  a.m[0x1e]=(a.m[0x1e]-1)&255
  game.fight.round_number=a.m[6]
  if fixture=="round2":
   game.fight.round_scene_visible=false
   a.player_picture=58
   a.opponent_picture=a.opponent_compositor.compose(128,58,0,Vector2i(a.m[0xb0],a.m[0xb1]))
   a.prime_display()
  game.fight.hp=a.m[0x391];game.fight.opponent_hp=a.m[0x398];game.fight._sync_resources()
  var dir="res://research/evidence/ring_projection/"+fixture+"/godot"
  DirAccess.make_dir_recursive_absolute(dir)
  for off in range(0,raw.size(),4110):
   var frame=int(raw.decode_u32(off))
   game.fight.sample=raw[off+2052];game.fight.step();game._process(1.0/60)
   if not game.fight.animation_failure.is_empty():push_error(game.fight.animation_failure);quit(1);return
   var row={"fixture":fixture,"frame":frame,"player":a.current("player"),"opponent":a.current("opponent"),"referee":a.current("referee"),"round_scene_visible":game.fight.round_scene_visible,"clock_visible":a.clock_visible,"round_fade":game.fight.round_fade,"state":game.fight.state}
   trace.append(row)
   var selected:=false
   for clip in clips:
    if clip.fixture==fixture and frame>=int(clip.start) and frame<=int(clip.end):selected=true;break
   if fixture=="full":selected=frame>=3430 and frame<=4030
   else:selected=frame>=6652 and frame<=7150
   if not selected or (frame%12!=0 and frame not in [3455,3537,3914,3945,6656,6700,7020,7128]):continue
   assert(game.mode!="paused","Capture unexpectedly paused")
   var path=dir+"/"+str(frame)+".png"
   if not (args.has("--reuse") and FileAccess.file_exists(path)):
    game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png(path)
   frames.append(row)
  print("MOTION CAPTURE ",fixture," complete")
 var suffix: String="" if args.is_empty() else "_"+args[0]
 var out=FileAccess.open("res://research/evidence/ring_projection/frames"+suffix+".json",FileAccess.WRITE)
 out.store_string(JSON.stringify(frames));out.close()
 var tout=FileAccess.open("res://research/evidence/ring_projection/trace"+suffix+".json",FileAccess.WRITE)
 tout.store_string(JSON.stringify(trace));tout.close()
 print("MOTION CAPTURE ",frames.size()," full-rate frames")
 game.queue_free();await process_frame;quit()
