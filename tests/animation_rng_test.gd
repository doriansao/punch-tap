extends SceneTree
const RNG=preload("res://scripts/recovered/nes_animation_rng.gd")
func _initialize() -> void:
 var cases: Array=JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/rng_cases.json"))
 for c in cases:
  var actual=RNG.advance(int(c[0]),int(c[1]),int(c[2]))
  if actual!=Vector2i(int(c[3]),int(c[4])):push_error("RNG mismatch");quit(1);return
 print("NES RNG: ",cases.size()," cases passed")
 quit()
