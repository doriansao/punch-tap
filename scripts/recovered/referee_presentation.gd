extends RefCounted
## Bank-11 high picture commands share the player VM. Retain the body while
## speech/count/attribute updates touch other background cells.
var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/referee_presentation.json"))
var body: Dictionary={}
var picture:=-1
var count:=0
var speech:=""
var speech_visible:=false
func select(m: PackedInt32Array) -> void:
 if m[0x60]==0:return
 var pose:=m[0x61]
 # Bank-11 decoded column streams: 153 blank count bubble, 154..163 digits,
 # 166 Fight!, 168 KO, 169 TKO. 167/174 touch attributes, not speech pixels.
 if pose==153:
  speech="";speech_visible=true
 elif pose>=154 and pose<=163:
  speech=str(pose-153);speech_visible=true
 elif pose in [166,168,169]:
  speech={166:"FIGHT!",168:"KO!",169:"TKO!"}[pose];speech_visible=true
 elif pose in [128,150,151]:
  speech="";speech_visible=false
 if pose>=154 and pose<=163:count=pose-153
 elif pose in [128,150,151,152,153,166,167,174]:count=0
 var key:=str(pose)
 if not data.commands.has(key):return
 var command: Dictionary=data.commands[key]
 if command.has("requires_previous"):assert(picture in [165,172],"Unrecovered predecessor for partial referee update")
 picture=m[0x61]
 body={} if command.get("clear",false) else command.duplicate(true)
func row(scroll: int) -> Dictionary:
 if body.is_empty():return {}
 var result:=body.duplicate(true)
 var b: Array=result.world_box
 var x:=posmod(int(b[0])-scroll,256)
 result.box=[x,b[1],b[2],b[3]]
 if result.has("draw_world_x"):result.draw_x=fposmod(float(result.draw_world_x)-scroll,256.0)
 result.count=count
 result.speech=speech
 result.speech_visible=speech_visible
 result.display_pose=picture
 return result
