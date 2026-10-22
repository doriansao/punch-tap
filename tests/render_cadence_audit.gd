extends SceneTree
class Preview extends "res://scripts/main.gd":
 func _notification(_what:int):pass
func _initialize():call_deferred("run")
func run():
 var game=Preview.new();root.add_child(game);game.sound_on=false;game._start_or_resume()
 var captured: Dictionary={}
 var samples: Array=[];var poses: Dictionary={};var previous:=-1;var holds: Array=[];var hold:=0
 var started:=Time.get_ticks_usec()
 for frame in 420:
  if frame%50==0:game.keyboard_high=true;game.perform_action("left" if (frame/50)%2==0 else "right")
  if frame%50==3:game.fight.release_all()
  await process_frame
  if frame>60:samples.append(game.get_process_delta_time())
  var row: Dictionary=game.fight.animation.current("opponent")
  var pose:=int(row.get("visual_pose_id",-1))
  poses[str(pose)]=int(row.get("art_frame",-1))
  if OS.get_cmdline_user_args().has("--capture") and pose in [25,26] and not captured.has(pose):
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://research/evidence/presentation/guard_"+str(pose)+".png")
   captured[pose]=true
  if pose!=previous:
   if hold>0:holds.append(hold)
   hold=0;previous=pose
  hold+=1
 var elapsed:=(Time.get_ticks_usec()-started)/1000000.0
 samples.sort()
 var result={"render_frames":420,"wall_seconds":elapsed,"mean_fps":420/elapsed,"frame_ms_p50":samples[samples.size()/2]*1000,"frame_ms_p95":samples[int(samples.size()*0.95)]*1000,"source_to_art":poses,"source_pose_holds_render_frames":holds,"scope":"Local live render cadence; short opening/head-punch sample, not all poses or devices."}
 var out=FileAccess.open("res://research/evidence/presentation/"+("cadence_capture.json" if OS.get_cmdline_user_args().has("--capture") else "cadence.json"),FileAccess.WRITE);out.store_string(JSON.stringify(result,"  "));out.close()
 print(JSON.stringify(result));game.queue_free();await process_frame;quit()
