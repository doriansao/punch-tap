extends SceneTree
const Presentation=preload("res://scripts/recovered/presentation_control.gd")
func _initialize() -> void:
 var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/normal_knockdowns_presentation_gate.bin")
 if raw.is_empty() or raw.size()%4100!=0:push_error("Missing presentation capture");quit(1);return
 var failures:=0
 for offset in range(0,raw.size(),4100):
  var m:=PackedInt32Array();m.resize(2048)
  for i in 2048:m[i]=raw[offset+4+i]
  m=Presentation.step(m)
  for address in [0x18,0x40,0x41,0x42,0x43,0x44,0x45]:
   if m[address]!=raw[offset+2052+address]:
    failures+=1
    if failures<8:print(raw.decode_u32(offset)," %04X got %d expected %d" % [address,m[address],raw[offset+2052+address]])
    break
 print("PRESENTATION CONTROL: ",raw.size()/4100," calls, ",failures," control/RNG mismatches")
 quit(1 if failures else 0)
