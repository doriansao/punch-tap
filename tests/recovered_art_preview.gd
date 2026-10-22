extends SceneTree
const Main=preload("res://scripts/main.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
 root.size=Vector2i(540,960)
 var game=Main.new();root.add_child(game);game.sound_on=false;game.set_physics_process(false);game._start_or_resume()
 for entry in [["idle",0],["left_head",12],["dodge_left",15],["dodge_right",15],["special",46],["opponent_down",80],["opponent_down",400],["player_down",20],["opponent_ko",650]]:
  game.animation_timeline.override_clip=entry[0];game.animation_timeline.override_age=entry[1];game.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://research/evidence/new_"+entry[0]+"_"+str(entry[1])+".png")
 quit()
