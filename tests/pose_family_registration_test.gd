extends SceneTree
# Exact translated/mirrored CHR body families measured by audit_pose_families.py.
# These constraints concern original-art registration, never combat rules.
func _initialize():
 var fight=load("res://scripts/fight_model_vm.gd").new();fight.start()
 assert(fight.animation.current("player").scroll==fight.animation.m[0x15],"Fight starts with stale idle scroll")
 for row in fight.animation.queue:
  assert(row.player.scroll==fight.animation.m[0x15],"Queued startup frame uses stale idle scroll")
 var g: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/animation_geometry.json"))
 var art: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/art_registration.json"))
 for pair in [[43,44],[43,45],[43,46],[47,48],[47,89],[47,90],[49,50],[49,91],[49,92],[51,59],[52,53],[85,86]]:
  var a: Dictionary=g.player[str(pair[0])];var b: Dictionary=g.player[str(pair[1])]
  var ra: Dictionary=art.player[int(a.art_frame)];var rb: Dictionary=art.player[int(b.art_frame)]
  assert(ra.texture==rb.texture and ra.region==rb.region and a.art_flip==b.art_flip,"Translated source body changes original art: "+str(pair))
 for pair in [[51,52],[51,53],[54,60]]:
  var a: Dictionary=g.player[str(pair[0])];var b: Dictionary=g.player[str(pair[1])]
  assert(a.art_frame==b.art_frame and a.art_flip!=b.art_flip,"Mirrored source body has inconsistent art: "+str(pair))
 for p in range(68,78):
  var row: Dictionary=g.player[str(p)]
  assert(row.draw_box[3]==61,"Offscreen return must crop, not shrink")
 assert(art.player[32].region==art.player[33].region)
 assert(art.player[32].texture.ends_with("teo_victory_v2.png") and art.player[34].texture.ends_with("teo_victory_v2.png"),"Victory must use raised-arm poses")
 print("POSE FAMILIES: translated/mirrored source bodies, fixed get-up extent, raised-arm victory")
 quit()
