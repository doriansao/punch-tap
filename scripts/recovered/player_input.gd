extends RefCounted
## Bank 11 $8119: button-edge acceptance, action lock, head/body selection.
var m := PackedInt32Array()
func _init() -> void: m.resize(2048)
func _consume(address: int) -> bool:
 if m[address]&128:
  m[address]&=127
  return true
 return false
func step() -> void:
 if m[4]!=255: return # Attract/demo controller is outside the fight.
 if m[0x50]==0 or m[0x50]>=64 or m[0x51]&128: return
 if m[0xbc]==0:
  if _consume(0xd5) or _consume(0xd7) or _consume(0xd9):
   m[0x53]=10; m[0x6b]=0
   return
 else:
  if _consume(0xd5):
   m[0x50]=139 if m[0xd2]&8 else 137
   m[0x6b]=int(bool(m[0xd2]&8))
   return
  if _consume(0xd7):
   m[0x50]=140 if m[0xd2]&8 else 138
   m[0x6b]=int(bool(m[0xd2]&8))
   return
  if m[0x342]!=0 and _consume(0xd9):
   m[0x341]=255
   if m[0x348]!=0: m[0x348]-=1
   m[0x50]=141; m[0x6b]=0
   return
 if m[0xd3]&128:
  var direction := m[0xd2]&7
  if direction:
   m[0x50]=131 if direction&1 else (133 if direction&2 else 135)
   m[0xd3]&=127
  m[0x6b]=0
 elif m[0x6b]!=0:
  var direction := m[0xd0]&7
  if direction: m[0x50]=131 if direction&1 else (133 if direction&2 else 135)
  m[0x6b]=0
