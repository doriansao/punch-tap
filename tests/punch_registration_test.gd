extends SceneTree
# Hand intent read from decoded source poses 14..33, not from runtime flip flags.
# The highest mint glove landmark must stay on that hand throughout the stroke.
func _initialize():
 var mapping: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/pose_art_map.json"))
 var art: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/art_registration.json"))
 var checked:=0
 for poses in [[14,15,16,17,23,24,25,26,27,42],[20,21,22,29,30,31,32,33,40,41]]:
  var expected: int=-1 if poses[0]==14 else 1
  for pose in poses:
   var frame: int=mapping.player[str(pose)]
   var reg: Dictionary=art.player[frame]
   var flip: bool=(float(pose) in mapping.player_flip)!=bool(reg.get("flip_correction",false))
   var side: float=float(reg.tip[0])-float(reg.region[2])*0.5
   if flip:side=-side
   assert(signf(side)==expected,"Punch changes hand at source pose %d / art %d" % [pose,frame])
   checked+=1
 print("PUNCH REGISTRATION: ",checked," source poses preserve striking hand through rise/extension/recovery")
 quit()
