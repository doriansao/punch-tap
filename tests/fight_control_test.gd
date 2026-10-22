extends SceneTree
const VM=preload("res://scripts/recovered/contact_vm.gd")
func _initialize() -> void:
 var vm=VM.new();var failures:=0
 for pair in [["clock",0x8759],["events",0xb069],["schedule_select",0xb10a],["schedule",0xb196],["score",0x86d0],["health",0x881e],["hearts",0x890d],["stars",0x8974]]:
  var bytes:=FileAccess.get_file_as_bytes("res://research/evidence/animation/normal_knockdowns_"+pair[0]+".bin")
  if bytes.is_empty():push_error("Missing "+pair[0]+" capture");quit(1);return
  var calls:=0;var mismatches:=0
  for offset in range(0,bytes.size()-4099,4100):
   vm.m.resize(2048)
   for i in 2048:vm.m[i]=bytes[offset+4+i]
   vm.step(pair[1]);calls+=1
   if not vm.error.is_empty():
    mismatches+=1
    if mismatches<5:print(pair[0]," ",bytes.decode_u32(offset)," ",vm.error)
    continue
   for i in 2048:
    if i>=256 and i<512:continue
    if vm.m[i]!=bytes[offset+2052+i]:
     mismatches+=1
     if mismatches<5:print(pair[0]," ",bytes.decode_u32(offset)," %04X got %d expected %d" % [i,vm.m[i],bytes[offset+2052+i]])
     break
  print(pair[0],": ",calls," calls, ",mismatches," mismatches");failures+=mismatches
 quit(1 if failures else 0)
