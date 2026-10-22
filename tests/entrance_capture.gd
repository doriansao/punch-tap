extends SceneTree
func _initialize():call_deferred("run")
func run():
 root.size=Vector2i(540,960)
 var game=load("res://scripts/main.gd").new();root.add_child(game);game.sound_on=false;game.set_physics_process(false);game.set_process(false);game._begin_entrance()
 for i in 887:
  game._physics_process(1.0/60.0);game._process(1.0/60.0)
  if i in [60,500,830]:
   game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://research/evidence/live_bout/entrance_%d.png"%i)
 print("ENTRANCE RENDER ",game.mode)
 quit(0 if game.mode=="fight" else 1)
