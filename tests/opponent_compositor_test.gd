extends SceneTree
const PoseComposer = preload("res://scripts/recovered/opponent_compositor.gd")
func _initialize() -> void:
 var c = PoseComposer.new()
 var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/compositor_cases.json"))
 var observed:=rows.size()
 rows.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/compositor_expanded_cases.json")))
 var failed := 0
 for r in rows:
  c.pose = r[2]
  var actual: Dictionary = c.compose(int(r[3]),int(r[4]),int(r[5]),Vector2i(int(r[6]),int(r[7])))
  if actual.is_empty() or c.pose != r[8] or not _same_box(actual.box,r[9]):
   failed += 1
   if failed < 10: print(r[0]," ",r[1]," ",c.error," ",actual.get("box")," expected ",r[9])
 print("OPPONENT COMPOSITION: ",observed," observed + ",rows.size()-observed," offline ROM cases; ",failed," mismatches")
 quit(1 if failed else 0)

func _same_box(a: Array,b: Array) -> bool:
 if a.size() != b.size(): return false
 for i in a.size():
  if int(a[i]) != int(b[i]): return false
 return true
