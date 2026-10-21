extends RefCounted
## Coupled recovered animation interpreters. The combat/count controller writes
## shared state; both actors execute commands against the same memory image.
const Coordinator=preload("res://scripts/recovered/actor_coordinator.gd")
const GuardAI=preload("res://scripts/recovered/opponent_guard_ai.gd")
const PlayerVM=preload("res://scripts/recovered/player_animation_vm.gd")
const OpponentVM=preload("res://scripts/recovered/opponent_animation_vm.gd")
const PoseComposer=preload("res://scripts/recovered/opponent_compositor.gd")
const PlayerInput=preload("res://scripts/recovered/player_input.gd")
const PlayerGetup=preload("res://scripts/recovered/player_getup.gd")
var geometry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/animation_geometry.json"))
var guard_ai=GuardAI.new()
var player_vm=PlayerVM.new()
var opponent_vm=OpponentVM.new()
var opponent_compositor=PoseComposer.new()
var input_handler=PlayerInput.new()
var getup_handler=PlayerGetup.new()
var m:=PackedInt32Array()
var player_picture:=0
var error:=""
var queue: Array=[]
var displayed: Dictionary={}
var opponent_picture: Dictionary={}
func _init() -> void: reset()
func reset() -> void:
 m.resize(2048);m.fill(0)
 for address in geometry.initial: m[int(address)]=int(geometry.initial[address])
 opponent_compositor.pose=opponent_compositor.data.initial
 player_picture=0;error=""
 player_vm.error="";opponent_vm.error="";opponent_compositor.error="";getup_handler.error=""
 opponent_picture=opponent_compositor.compose(0,m[0xa1],0,Vector2i(m[0xb0],m[0xb1]))
 displayed={"player":player_row(),"opponent":opponent_picture.duplicate(true)}
 queue=[displayed.duplicate(true),displayed.duplicate(true)]
func opponent_step() -> void:
 opponent_vm.m=m;opponent_vm.step();m=opponent_vm.m
 for request in opponent_vm.composition_requests:
  opponent_picture=opponent_compositor.compose(request[0],request[1],request[2],Vector2i(request[3],request[4]))
 if not opponent_vm.error.is_empty():error=opponent_vm.error
func compose_opponent() -> void:
 opponent_picture=opponent_compositor.compose(m[0xa0],m[0xa1],m[0xa2],Vector2i(m[0xb0],m[0xb1]))
 m[0xa0]=0;m[0xa2]=0
 if not opponent_compositor.error.is_empty():error=opponent_compositor.error
func input_step() -> void:
 input_handler.m=m;input_handler.step();m=input_handler.m
func player_step() -> void:
 player_vm.m=m;player_vm.step();m=player_vm.m
 if not player_vm.error.is_empty():error=player_vm.error
func getup_step() -> void:
 getup_handler.m=m;getup_handler.step();m=getup_handler.m
 if not getup_handler.error.is_empty():error=getup_handler.error
func select_player_picture() -> void:
 if m[0x60]!=0 and m[0x61]<128:player_picture=m[0x61]
func player_row() -> Dictionary:
 if player_picture in [58,64,65,66,67]: return {"box":[],"tip":[],"display_pose":player_picture}
 var key:=str(player_picture)
 if not geometry.player.has(key):
  error="Unrecovered player geometry "+key
  return {}
 var row: Dictionary=geometry.player[key].duplicate(true)
 var full: Array=row.world_box
 var x:=posmod(int(full[0])-m[0x15],256)
 if x>224:x-=256
 var old_full: Array=row.draw_box
 var dx:=x-int(old_full[0])
 row.draw_box=[x,full[1],full[2],full[3]]
 row.box[0]=int(row.box[0])+dx
 if not row.tip.is_empty():row.tip[0]=float(row.tip[0])+dx
 row.scroll=m[0x15]
 return row
func present() -> void:
 select_player_picture()
 queue.append({"player":player_row(),"opponent":opponent_picture.duplicate(true)})
 displayed=queue.pop_front()
func tick() -> void:
 # The recorded call order is opponent VM/composition, player input/VM,
 # picture preparation, then get-up input. Contacts interrupt the next tick.
 m[0x60]=0
 guard_ai.m=m;guard_ai.step();m=guard_ai.m
 opponent_step();compose_opponent();input_step();player_step()
 if m[0x60]&128:m[0x60]=1
 getup_step();present();m=Coordinator.step(m)
func current(role: String) -> Dictionary:return displayed.get(role,{})
func begin_knockdown(opponent_down: bool, getup_count: int=6, recovery_hp: int=80) -> void:
 m[0xcf]=0;m[0xc1]=153;m[0x36]=0
 if opponent_down:
  m[5]=1
  var count_script: Array=[15 if getup_count>0 else 0,153,227,193,153+getup_count if getup_count>0 else 0,7,234,250,125,5,234]
  for i in count_script.size():m[0xc0+i]=int(count_script[i])
  m[0x397]=m[0x391];m[0x39e]=recovery_hp
 else:
  m[5]=2;m[0xbb]=128;m[0x70]=67
  var count_script: Array=[15,153,128,5,234]
  for i in count_script.size():m[0xc0+i]=int(count_script[i])
  m[0x3c3]=7;m[0x3c4]=17;m[0x5d2]=17;m[0x3c1]=2
  m[0x5d0]=126;m[0x5d1]=147
