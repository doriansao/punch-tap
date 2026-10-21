extends SceneTree
const VM = preload("res://scripts/recovered/player_animation_vm.gd")
func _initialize() -> void:
 var vm = VM.new()
 var checked: Array = range(0x50,0x80)
 checked.append_array([0x15,0x18,0x99,0xbc,0xd3,0xf0,0xf1,0xf2,0xf3,0x300,0x301,0x391,0x398,0x48d,0x48e,0x4a0])
 var total := 0
 var failed := 0
 for case in ["visual_audit","normal_knockdowns","player_getup_wide","idle_long","right_knockdowns"]:
  var data := FileAccess.get_file_as_bytes("res://research/evidence/animation/"+case+"_vm.bin")
  for offset in range(0,data.size(),4100):
   var frame := data.decode_u32(offset)
   vm.load_ram(data.slice(offset+4,offset+2052)); vm.step(); total += 1
   if not vm.error.is_empty():
    failed += 1
    if failed < 10: print(case, " ", frame, " ", vm.error)
    continue
   for address in checked:
    if vm.m[address] != data[offset+2052+address]:
     failed += 1
     if failed < 10: print(case," ",frame," address %04X expected %d actual %d" % [address,data[offset+2052+address],vm.m[address]])
     break
 print("GODOT PLAYER VM: ",total," calls; ",failed," mismatches")
 quit(1 if failed else 0)
