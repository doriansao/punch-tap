extends SceneTree
const InputHandler=preload("res://scripts/recovered/player_input.gd")
const GetupHandler=preload("res://scripts/recovered/player_getup.gd")
func _initialize() -> void:
 var total:=0;var failed:=0
 for kind in ["player_input","player_getup"]:
  var handler = InputHandler.new() if kind=="player_input" else GetupHandler.new()
  var checked: Array=[0x50,0x53,0x6b,0xd3,0xd5,0xd7,0xd9,0x341,0x348] if kind=="player_input" else [0x60,0x61,0x63,0x64,0x66,0x67,0x70,0xd5,0xd7,0x3c3,0x3c4,0x397,0x39e,0x321,0x322,0x3c5,0x3cb,0x36,0x3c1]
  var count:=0;var errors:=0
  for case in ["visual_audit","normal_knockdowns","player_getup_wide","idle_long","right_knockdowns"]:
   var path: String="res://research/evidence/animation/"+case+"_"+kind+".bin"
   if not FileAccess.file_exists(path): continue
   var bytes:=FileAccess.get_file_as_bytes(path)
   for offset in range(0,bytes.size()-4099,4100):
    if kind=="player_input" and bytes[offset+8]!=255: continue
    for i in 2048: handler.m[i]=bytes[offset+4+i]
    handler.step();count+=1
    if kind=="player_getup" and not handler.error.is_empty():
     errors+=1
     if errors<10: print(case," ",bytes.decode_u32(offset)," ",handler.error)
     continue
    for a in checked:
     if handler.m[a]!=bytes[offset+2052+a]:
      errors+=1
      if errors<10: print(kind," ",case," ",bytes.decode_u32(offset)," %04X: got %d expected %d" % [a,handler.m[a],bytes[offset+2052+a]])
      break
  print(kind,": ",count," calls; ",errors," mismatches")
  total+=count;failed+=errors
 quit(1 if failed else 0)
