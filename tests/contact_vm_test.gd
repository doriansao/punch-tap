extends SceneTree
const Contact=preload("res://scripts/recovered/contact_vm.gd")
func _initialize() -> void:
 var vm=Contact.new()
 var failures:=0
 for case in ["normal_knockdowns","player_getup_wide"]:
  var bytes:=FileAccess.get_file_as_bytes("res://research/evidence/animation/"+case+"_collision.bin")
  if bytes.is_empty():push_error("Missing collision capture "+case);quit(1);return
  var calls:=0;var mismatch:=0;var contacts:=0
  for offset in range(0,bytes.size()-4099,4100):
   vm.m.resize(2048)
   for i in 2048:vm.m[i]=bytes[offset+4+i]
   if (vm.m[0x58]|vm.m[0x98])&128:contacts+=1
   vm.step();calls+=1
   if not vm.error.is_empty():
    mismatch+=1
    if mismatch<8:print(case," frame ",bytes.decode_u32(offset)," ",vm.error)
    continue
   for i in 2048:
    if i>=256 and i<512:continue # CPU call stack is not game state.
    if vm.m[i]!=bytes[offset+2052+i]:
     mismatch+=1
     if mismatch<8:print(case," frame ",bytes.decode_u32(offset)," %04X got %d expected %d" % [i,vm.m[i],bytes[offset+2052+i]])
     break
  print(case,": ",calls," calls, ",contacts," contacts, ",mismatch," RAM mismatches")
  failures+=mismatch
 quit(1 if failures else 0)
