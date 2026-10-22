extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 game.set_process(false);game.set_physics_process(false)
 var rows:Array=JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/ring_projection/frames.json"))
 var checked:=0;var failures:=0
 var heights:Dictionary={9:240.0,13:245.0,14:195.0,22:220.0,23:230.0,32:300.0,33:265.0,34:195.0,35:220.0,36:245.0,37:330.0}
 for row in rows:
  var o:Dictionary=row.opponent
  if o.box.is_empty():continue
  var full:Array=o.get("draw_box",o.box);var pose:=int(o.art_frame)
  var h:float=heights.get(pose,280.0)
  var original:Vector2=game.source_point(Vector2(float(full[0])+float(full[2])*0.5,float(full[1])))
  var anchor:Vector2=game._opponent_mat_anchor(full,pose,h,original)
  var r:Array=game.art_registration.opponent[pose].region
  var width:=float(r[2])/float(r[3])*h
  if float(full[1])+float(full[3])<=148:
   checked+=1
   if anchor.x-width*0.5<16 or anchor.x+width*0.5>524 or anchor.y<122 or anchor.y+h>646:
    failures+=1;print("Outside ring: ",row.frame," ",anchor," ",width," ",h)
   if pose in [14,34] and anchor.y<334:failures+=1;push_error("Prone torso crosses back ropes")
 # Fighting-depth transforms must remain identical to contact registration.
 var original:=Vector2(271,256)
 if game._opponent_mat_anchor([119,90,31,98],24,280,original)!=original:failures+=1
 print("RING PROJECTION: ",checked," distant/fallen frames; ",failures," failures; fighting-depth unchanged")
 game.queue_free();await process_frame;quit(1 if failures else 0)
