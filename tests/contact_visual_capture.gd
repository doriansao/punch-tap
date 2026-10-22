extends SceneTree
func _initialize():call_deferred("capture")
func snap(game,label):
 game._process(1.0/60.0);game.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://research/evidence/live_bout/"+label+".png")
func capture():
 root.size=Vector2i(540,960)
 var game=load("res://scripts/main.gd").new();root.add_child(game);game.sound_on=false;game.set_physics_process(false);game.set_process(false)
 for hand in ["left","right"]:
  game._start_or_resume();game.fight.act("head",hand);game.fight.release(hand)
  for i in 16:
   game.fight.step();game._process(1.0/60.0)
   if i==10:await snap(game,hand+"_head_contact")
   if i==13:await snap(game,hand+"_head_reaction")
 game._start_or_resume()
 var hit_at:=-1
 for i in 1600:
  game.fight.step();game._process(1.0/60.0)
  if hit_at<0 and game.fight.received>0:hit_at=i;await snap(game,"incoming_contact")
  if hit_at>=0 and i==hit_at+3:await snap(game,"incoming_reaction");break
 print("CONTACT VISUALS saved; incoming tick ",hit_at)
 quit()
