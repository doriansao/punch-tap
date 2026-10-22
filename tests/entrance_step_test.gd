extends SceneTree
const VM = preload("res://scripts/recovered/opponent_animation_vm.gd")
func _initialize() -> void:
 var vm = VM.new()
 var checked: Array = range(0x90,0xa0)
 checked.append_array(range(0xb0,0xbb))
 checked.append_array([0x4a,0x4b,0x4c,0x10,0x18,0x80,0x52,0x53,0x5a,0xf0,0xf1,0xf2,0xf3])
 checked.append_array(range(0x300,0x307))
 var total := 0
 var failed := 0
 for case in ["normal_knockdowns_entrance"]:
  var data := FileAccess.get_file_as_bytes("res://research/evidence/animation/"+case+"_opponent_step.bin")
  for offset in range(0,data.size(),4100):
   var frame := data.decode_u32(offset)
   vm.load_ram(data.slice(offset+4,offset+2052)); vm.step(); total += 1
   if not vm.error.is_empty():
    failed += 1
    if failed < 10: print(case," ",frame," ",vm.error)
    continue
   for address in checked:
    if vm.m[address] != data[offset+2052+address]:
     failed += 1
     if failed < 10: print(case," ",frame," address %04X expected %d actual %d" % [address,data[offset+2052+address],vm.m[address]])
     break
 assert(total > 0, "Entrance capture is required")
 print("GODOT ENTRANCE STEP: ",total," commands; ",failed," mismatches")
 quit(1 if failed else 0)
