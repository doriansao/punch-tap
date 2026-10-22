extends SceneTree
const Main=preload("res://scripts/main.gd")
var manifest: Array=[]
func _initialize() -> void:call_deferred("capture")
func snap(game,label: String) -> void:
 game.hit_flash=0;game.opponent_flash=0;game.block_flash=0
 game.queue_redraw()
 await process_frame;await RenderingServer.frame_post_draw
 var path:="res://research/evidence/live_bout/"+label+".png"
 root.get_texture().get_image().save_png(path)
 var f=game.fight
 manifest.append({"image":label+".png","tick":f.ticks,"state":f.state,"hp":f.hp,"opponent_hp":f.opponent_hp,"stars":f.stars,"opponent_downs":f.opponent_downs,"result":f.result,"verdict":f.verdict})
func capture() -> void:
 root.size=Vector2i(540,960)
 DirAccess.make_dir_recursive_absolute("res://research/evidence/live_bout")
 var game=Main.new();root.add_child(game);game.sound_on=false;game.set_physics_process(false);game.set_process(false);game._start_or_resume()
 await snap(game,"ready")
 var seen: Dictionary={}
 for tick in 12000:
  var f=game.fight
  if f.state=="player_down" and tick%8==0:f.act("head","left");f.release("left")
  elif tick%25==0 and f.state not in ["taunt","opening","opponent_down","countout"]:
   var hand: String="left" if (tick/25)%2==0 else "right"
   f.act("special" if f.stars>0 else "head",hand);f.release(hand);f.release("special")
  f.step()
  game._process(1.0/60.0)
  var label:=""
  if f.hits>0 and f.state=="reaction":label="contact"
  if f.state=="opponent_down" and f.down_age==100:label="knockdown"
  if f.state=="opponent_down" and f.count>0:label="count"
  if f.opponent_downs>0 and f.state=="ready":label="recovered"
  if f.stars>0:label="star"
  if not label.is_empty() and not seen.has(label):seen[label]=true;await snap(game,label)
  if not f.active:break
 await snap(game,"result")
 var file=FileAccess.open("res://research/evidence/live_bout/manifest.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"scope":"Live natural-input bout; no replay override or health/resource fixtures.","frames":manifest},"  "));file.close()
 print("LIVE CAPTURE: ",game.fight.result," ",game.fight.verdict," at ",game.fight.ticks,"; ",game.fight.animation_failure)
 quit(0 if game.fight.result=="win" and game.fight.animation_failure.is_empty() else 1)
