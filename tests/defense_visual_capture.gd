extends SceneTree
class Preview extends "res://scripts/main.gd":
 func _notification(_what: int) -> void:pass # Offline capture must ignore focus loss.
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons() -> int:return sample
func _initialize():call_deferred("capture")
func capture():
 root.size=Vector2i(540,960)
 var game=Preview.new();game.fight=Adapter.new();root.add_child(game)
 game.sound_on=false;game.set_physics_process(false);game.set_process(false);game._start_or_resume()
 var raw=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_defense_fight.bin")
 var fight=game.fight;var a=fight.animation
 for i in 2048:a.m[i]=raw[4+i]
 a.m[0x1e]=(a.m[0x1e]-1)&255
 fight.hp=a.m[0x391];fight.opponent_hp=a.m[0x398];fight._sync_resources()
 DirAccess.make_dir_recursive_absolute("res://research/evidence/defense_audit/godot")
 var rows: Array=[]
 for off in range(0,raw.size(),4110):
  var frame=int(raw.decode_u32(off))
  fight.sample=raw[off+2052];fight.step();game._process(1.0/60.0)
  if not fight.animation_failure.is_empty():push_error(fight.animation_failure);quit(1);return
  var post=off+2062
  var row={"frame":frame,"buttons":fight.sample,"source_player_pose":raw[post+0x61],"source_selector":raw[post+0xa1],"referee":a.current("referee"),"player":a.current("player"),"opponent":a.current("opponent"),"hp":fight.hp,"opponent_hp":fight.opponent_hp,"phase":a.m[5],"downs":a.m[0x3d1],"state":fight.state}
  if frame>=2900 and frame%4==0:
   game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://research/evidence/defense_audit/godot/"+str(frame)+".png")
   rows.append(row)
 var out=FileAccess.open("res://research/evidence/defense_audit/frames.json",FileAccess.WRITE);out.store_string(JSON.stringify(rows));out.close()
 print("DEFENSE RENDER ",rows.size()," pairs; ",fight.result," ",fight.verdict)
 game.queue_free();await process_frame;quit()
