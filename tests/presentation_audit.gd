extends SceneTree
class Main extends "res://scripts/main.gd":
 func _notification(_what: int) -> void:pass # Deterministic offline capture.
func _initialize():call_deferred("run")
func run():
 var game=Main.new();root.add_child(game);game.sound_on=false
 game.set_physics_process(false);game.set_process(false)
 var enter:=InputEventKey.new();enter.keycode=KEY_ENTER;enter.pressed=true
 game._input(enter)
 assert(game.mode=="entrance","Enter must not bypass the entrance")
 var log: Array=[];var last:="";var captures:=0
 DirAccess.make_dir_recursive_absolute("res://research/evidence/presentation")
 for tick in 887:
  var row: Dictionary=game.entrance.current("referee")
  var signature:=str(row.get("display_pose",-1))+str(row.get("speech",""))+str(row.get("speech_visible",false))
  if signature!=last:
   log.append({"tick":tick,"source_frame":1130+tick,"referee":row});last=signature
  if row.get("speech","")=="FIGHT!" and captures==0:
   game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://research/evidence/presentation/fight.png");captures+=1
  game._physics_process(1.0/60)
 assert(captures==1,"Recovered opening must show FIGHT speech")
 var out=FileAccess.open("res://research/evidence/presentation/entrance.json",FileAccess.WRITE);out.store_string(JSON.stringify(log));out.close()
 game.mode="intro";game.clock=2;game._update_buttons();game.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://research/evidence/presentation/title.png")
 print("PRESENTATION: Enter runs entrance; recovered FIGHT cue observed; title/opening captured")
 game.queue_free();await process_frame;quit()
