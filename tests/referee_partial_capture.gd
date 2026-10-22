extends SceneTree
class Preview extends "res://scripts/main.gd":
 func toggle_pause() -> void:pass
 func _input(_event:InputEvent) -> void:pass
 func _notification(_what:int):pass
func _initialize():call_deferred("capture")
func capture():
 root.size=Vector2i(540,960)
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/referee_partial_execution.json"))
 var game=Preview.new();root.add_child(game);game.mode="fight";game.sound_on=false
 game.set_physics_process(false);game.set_process(false);game._update_buttons()
 var vm=load("res://scripts/recovered/player_animation_vm.gd").new()
 var ref=load("res://scripts/recovered/referee_presentation.gd").new()
 for i in 2048:vm.m[i]=int(data.initial[i])
 var out="res://research/evidence/referee_partial/godot"
 DirAccess.make_dir_recursive_absolute(out)
 for frame in range(70):
  vm.m[0x60]=0;vm.step();ref.select(vm.m)
  game.fight.animation.displayed={"player":{"box":[]},"opponent":{"box":[]},"referee":ref.row(0)}
  game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(out+"/"+str(frame)+".png")
 game.queue_free();await process_frame;quit()
