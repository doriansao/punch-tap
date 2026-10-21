extends RefCounted
## Logical body composition recovered at $C890. Partial selectors preserve the
## preceding torso/legs. Numeric transitions carry no Nintendo artwork.
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/opponent_composition.json"))
var pose: String
var error := ""
func _init() -> void: pose = data.initial
func compose(flags: int, selector: int, alternate: int, anchor: Vector2i) -> Dictionary:
 if flags & 128:
  var key := "%s:%d:%d" % [pose,selector,alternate]
  var full_key := "%d:%d" % [selector,alternate]
  if data.transitions.has(key): pose = data.transitions[key]
  elif selector < 128 and data.full.has(full_key): pose = data.full[full_key]
  else:
   error = "Unrecovered composition transition " + key
   return {}
 if not data.poses.has(pose):
  error = "Unrecovered composition body " + pose
  return {}
 var row: Dictionary = data.poses[pose].duplicate(true)
 var b: Array = row.relative_box
 row.box = [anchor.x+int(b[0]),anchor.y+int(b[1]),b[2],b[3]]
 row.draw_box = row.box.duplicate()
 row.crop_y = [0.0,1.0]
 row.tip = []
 row.composition = pose
 return row
