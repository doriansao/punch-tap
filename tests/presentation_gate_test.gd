extends SceneTree
const Gate=preload("res://scripts/recovered/presentation_gate.gd")
func _initialize() -> void:
 var path:="res://research/evidence/animation/normal_knockdowns_presentation_gate.bin"
 if not FileAccess.file_exists(path):
  push_error("Run collision_normal_knockdowns.lua in Mesen first");quit(1);return
 var bytes:=FileAccess.get_file_as_bytes(path)
 var calls:=0;var failures:=0;var releases:=0
 for offset in range(0,bytes.size()-4099,4100):
  var m:=PackedInt32Array();m.resize(2048)
  for a in 2048:m[a]=bytes[offset+4+a]
  var before:=m[0x40]
  m=Gate.step(m);calls+=1
  if before==3 and m[0x40]==4:releases+=1
  if m[0x40]!=bytes[offset+2052+0x40]:
   failures+=1
   if failures<5:print("frame ",bytes.decode_u32(offset)," gate got ",m[0x40]," expected ",bytes[offset+2052+0x40])
 print("Presentation handshake: ",calls," observed calls; ",releases," finish releases; ",failures," mismatches (field $40 only)")
 quit(1 if failures or calls==0 or releases==0 else 0)
