extends SceneTree
const GuardAI=preload("res://scripts/recovered/opponent_guard_ai.gd")
func _initialize() -> void:
 var ai=GuardAI.new()
 var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://research/evidence/animation/guard_ai_cases.json"))
 var failed:=0
 for row in data.cases:
  for i in 2048:ai.m[i]=int(row[0][i])
  ai.step()
  for i in data.fields.size():
   var a:=int(data.fields[i])
   if ai.m[a]!=int(row[1][i]):
    failed+=1
    if failed<10:print("Guard AI %04X expected %d got %d" % [a,int(row[1][i]),ai.m[a]])
    break
 print("Guard AI: ",data.cases.size()," ROM-executed oracle cases; ",failed," mismatches")
 quit(1 if failed else 0)
