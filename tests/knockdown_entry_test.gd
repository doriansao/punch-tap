extends SceneTree
const Entry=preload("res://scripts/recovered/knockdown_entry.gd")
const Coordinator=preload("res://scripts/recovered/actor_coordinator.gd")
func _initialize() -> void:
 var path:="res://research/evidence/animation/knockdown_entry_cases.json"
 if not FileAccess.file_exists(path):
  push_error("Generate local oracle fixtures with recover_knockdown_entry.py first");quit(1);return
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
 var failures:=0
 for row in data.cases:
  var m:=PackedInt32Array(row.before)
  m=Coordinator.step(m) if row.kind=="coordinator" else Entry.apply(m,row.kind=="opponent")
  for i in data.fields.size():
   var address: int=data.fields[i]
   if m[address]!=int(row.after[i]):
    failures+=1
    if failures<10:print(row.kind," %04X got %d expected %d" % [address,m[address],int(row.after[i])])
    break
 print("KO entry/coordinator: ",data.cases.size()," ROM oracle cases; ",failures," mismatches")
 for kind in ["player_knockdown_entry","opponent_knockdown_entry","actor_coordinator"]:
  var case: String="player_getup_wide" if kind=="player_knockdown_entry" else "normal_knockdowns"
  var capture_path: String="res://research/evidence/animation/"+case+"_"+kind+".bin"
  if not FileAccess.file_exists(capture_path):
   print(kind,": live capture unavailable (not validated)");continue
  var bytes:=FileAccess.get_file_as_bytes(capture_path)
  var calls:=0;var mismatches:=0
  for offset in range(0,bytes.size()-4099,4100):
   var m:=PackedInt32Array();m.resize(2048)
   for a in 2048:m[a]=bytes[offset+4+a]
   m=Coordinator.step(m) if kind=="actor_coordinator" else Entry.apply(m,kind=="opponent_knockdown_entry")
   calls+=1
   for a in 2048:
    if a>=256 and a<512:continue
    if m[a]!=bytes[offset+2052+a]:
     mismatches+=1
     if mismatches<5:print(kind," frame ",bytes.decode_u32(offset)," %04X got %d expected %d" % [a,m[a],bytes[offset+2052+a]])
     break
  print(kind,": ",calls," observed calls; ",mismatches," mismatches")
  failures+=mismatches
 quit(1 if failures else 0)
