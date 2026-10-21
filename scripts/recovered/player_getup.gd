extends RefCounted
## Fixed bank $B457: get-up presses, decay, queued picture updates and recovery.
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/player_presentation.json"))
var m := PackedInt32Array()
var error := ""
var prepared_pose := -1
func _init() -> void: m.resize(2048)
func _prepare() -> void:
 if m[0x60]!=0:
  m[0x3c3]|=128
  return
 m[0x61]=m[0x70];m[0x60]=129
 var key := str(m[0x61])
 if not data.poses.has(key):
  error="Unrecovered get-up picture "+key
  return
 var p: Dictionary=data.poses[key]
 m[0x63]=int(p.destination)&255;m[0x64]=int(p.destination)>>8
 m[0x66]=int(p.stream)&255;m[0x67]=int(p.stream)>>8
 m[0x60]=1;prepared_pose=m[0x61]
func step() -> void:
 prepared_pose=-1
 if m[0xcf]==0: return
 var left := m[0x3c3]
 if left&128:
  m[0x3c3]=left&127;_prepare();return
 if left==0: return
 var pressed := false
 if m[0xd5]&128:
  m[0xd5]&=127;pressed=true
 elif m[0xd7]&128: pressed=true
 if pressed:
  m[0xd7]&=127;m[0x3c3]-=1;left=m[0x3c3]
  if left==0:
   var pointer := m[0x5d0]+256*m[0x5d1]
   var index := ((m[0xc1]-153+m[0x3c1])&255)+pointer-int(data.getup_table_base)
   if index<0 or index>=data.getup_table.size():
    error="Unrecovered get-up table index %d" % index
    return
   var value := int(data.getup_table[index])
   m[0x39e]=m[0x398];m[0x397]=m[0x391];m[0x397]=(value&15)*8
   m[0x322]=maxi(1,((value&48)>>4)*3);m[0x321]=0
   m[0x3c5]=(value>>6)&1
   if value&128: m[0x3cb]=1
   m[0x36]=2;m[0x3c1]=(m[0x3c1]+10)&255
  if left>=5: m[0x70]=58
  else: m[0x70]=(72-left)&255
  _prepare()
 elif left>=5:
  if m[0xd4]==0 and m[0xd6]==0 and m[0x70]==58:
   m[0x70]=67;_prepare()
 else:
  m[0x3c4]=(m[0x3c4]-1)&255
  if m[0x3c4]==0:
   m[0x3c4]=m[0x5d2];m[0x3c3]=(left+1)&255;m[0x70]=(72-m[0x3c3])&255;_prepare()
