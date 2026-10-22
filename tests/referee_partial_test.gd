extends SceneTree
func _initialize():
 var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/referee_partial_execution.json"))
 var vm=load("res://scripts/recovered/player_animation_vm.gd").new()
 var ref=load("res://scripts/recovered/referee_presentation.gd").new()
 for i in 2048:vm.m[i]=int(data.initial[i])
 var art:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/referee_art.json"))
 for pose in [6,7,8]:
  assert(art[pose].body_height==art[6].body_height,"Raised arm must retain body scale")
  assert(art[pose].foot_x>=0 and art[pose].foot_x<art[pose].region[2])
 var pulses:=0;var prior:=-1
 for row in data.frames:
  vm.m[0x60]=0;vm.step();ref.select(vm.m)
  for address in range(0x50,0x62):
   if vm.m[address]!=int(row.ram[address]):push_error("Partial referee interpreter mismatch");quit(1);return
  if vm.m[0x60]!=0:
   var pose:int=vm.m[0x61]
   if pose==172:
    assert(prior==165,"Partial update must retain predecessor 165")
    for i in 4:assert(int(ref.body.world_box[i])==[93,136,21,48][i],"Partial sprite must not shrink the referee")
    pulses+=1
   assert(is_equal_approx(float(ref.row(0).draw_x),105.5),"Unchanged feet must retain source anchor")
   prior=pose
 assert(pulses==4,"Exercise four complete arm-lowering transitions")
 print("REFEREE PARTIAL: 70 ROM-executed ticks, four 165 -> 172 transitions; retained body extent")
 quit()
