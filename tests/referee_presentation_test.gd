extends SceneTree
class Adapter extends "res://scripts/fight_model_vm.gd":
 var sample:=0
 func _raw_buttons() -> int:return sample
func _initialize() -> void:
 var raw:=FileAccess.get_file_as_bytes("res://research/evidence/animation/coupled_full_fight.bin")
 var decoded: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/player_compositor.json"))
 if raw.size()!=4959*4110:push_error("Missing full fight fixture");quit(1);return
 var fight=Adapter.new();fight.start();var a=fight.animation
 for i in 2048:a.m[i]=raw[4+i]
 a.m[0x1e]=(a.m[0x1e]-1)&255
 var expected: Dictionary={};var queue: Array=[{},{}]
 var count:=0
 var visible:=0;var changes:=0;var previous:=-1
 for off in range(0,raw.size(),4110):
  var post:=off+2062
  var pose:=int(raw[post+0x61])
  if raw[post+0x60]!=0:
   if pose>=154 and pose<=163:count=pose-153
   elif pose in [128,150,151,152,153,166,167,174]:count=0
   if pose==128:expected={}
   elif (pose>=129 and pose<=152) or pose in [164,165,173]:
    expected={"display_pose":pose,"world_box":decoded[str(pose)].box}
  var row:=expected.duplicate(true)
  if not row.is_empty():
   row.count=count
   var b: Array=row.world_box
   row.box=[posmod(int(b[0])-int(raw[post+0x15]),256),b[1],b[2],b[3]]
  queue.append(row);row=queue.pop_front()
  fight.sample=raw[off+2052];fight.step()
  var actual: Dictionary=a.current("referee")
  if actual.is_empty()!=row.is_empty() or (not row.is_empty() and (actual.box!=row.box or actual.display_pose!=row.display_pose or actual.count!=row.count)):
   push_error("Referee source sequence/position mismatch frame %d" % raw.decode_u32(off));quit(1);return
  if not actual.is_empty():
   visible+=1
   if actual.display_pose!=previous:changes+=1
   previous=actual.display_pose
 if changes<100:push_error("Walk/count transitions not exercised");quit(1);return
 print("REFEREE: 4959 frames, ",visible," visible, ",changes," body transitions; source command/position parity. Original silhouette is authored.")
 quit()
