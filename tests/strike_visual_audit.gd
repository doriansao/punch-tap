extends SceneTree
class Preview extends "res://scripts/main.gd":
 func _notification(_what: int) -> void:pass
func _initialize():call_deferred("capture")
func capture():
 root.size=Vector2i(540,960)
 var game=Preview.new();root.add_child(game);game.sound_on=false;game.set_physics_process(false);game.set_process(false)
 DirAccess.make_dir_recursive_absolute("res://research/evidence/strike_audit")
 var records: Array=[]
 for target in ["head","body"]:
  for hand in ["left","right"]:
   game._start_or_resume();game.fight.act(target,hand);game.fight.release(hand)
   for i in 25:
    game.fight.step();game._process(1.0/60.0)
    var a=game.fight.animation
    records.append({"target":target,"hand":hand,"tick":game.fight.ticks,"contact_result":a.m[0x58],"hp":game.fight.opponent_hp,"player":a.current("player"),"opponent":a.current("opponent")})
    if i in [8,10,11,12,13,14,16,20]:
     game.queue_redraw();await process_frame;await RenderingServer.frame_post_draw
     root.get_texture().get_image().save_png("res://research/evidence/strike_audit/%s_%s_%02d.png" % [target,hand,i+1])
 var out=FileAccess.open("res://research/evidence/strike_audit/frames.json",FileAccess.WRITE);out.store_string(JSON.stringify(records));out.close()
 game.queue_free();await process_frame;print("STRIKE AUDIT 4 attacks / 100 frames / 32 previews");quit()
