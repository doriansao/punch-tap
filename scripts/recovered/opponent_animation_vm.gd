extends RefCounted
## Recovered opponent command semantics; first-fight program uses no ROM at runtime.
var program: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/opponent_animation_program.json"))
var m := PackedInt32Array()
var error := ""
var continue_dispatch := false
var composition_requests: Array=[]
func _init() -> void: m.resize(2048)
func load_ram(bytes: PackedByteArray) -> void:
 for i in mini(2048,bytes.size()): m[i] = bytes[i]
 error = ""
func pointer() -> int: return m[0x94] + 256*m[0x95]
func set_pointer(value: int) -> void:
 m[0x94] = value & 255; m[0x95] = value >> 8
func move_packed(value: int) -> void:
 var dx := value >> 4
 var dy := value & 15
 m[0xb0] = (m[0xb0] + (dx if dx < 8 else dx-16)) & 255
 m[0xb1] = (m[0xb1] + (dy if dy < 8 else dy-16)) & 255
 m[0xa0] = 1
func command() -> void:
 var pc := pointer()+m[0x93]
 continue_dispatch = false
 if not program.commands.has(str(pc)):
  error = "Unrecovered opponent command %04X" % pc; return
 var node: Dictionary = program.commands[str(pc)]
 var op: String = node.op
 var a: Array = node.arg
 var low := int(node.duration)
 var old_cursor := m[0x93]
 m[0x93] = (old_cursor + int(node.size)) & 255
 match op:
  "pose","pose_alt":
   if op == "pose_alt": m[0xa2] = 1
   m[0x92] = low; m[0xa1] = int(a[0]); m[0xa0] = 128; continue_dispatch = node.chain
  "pose_position","pose_position_alt","position":
   if op == "pose_position_alt": m[0xa2] = 1
   m[0x92] = low
   if op != "position": m[0xa1] = int(a[0]); m[0xa0] = 128
   m[0xb0] = int(a[-2]); m[0xb1] = int(a[-1])
  "random_branch":
   var old_random := m[0x18]
   if low != 15:
    var carry := 0
    for bit in 3:
     var next_carry := m[0x18] & 1
     m[0x18] = (m[0x18] >> 1) | (carry << 7); carry = next_carry
   if low == 15 or low > (old_random & 15): m[0x93] = int(a[0])
   continue_dispatch = true
  "move","move_repeat":
   if op == "move": m[0x92] = low
   else: m[0x92] = (low & 3)+1; m[0x9b] = m[0x92]; m[0x9a] = (low >> 2)+1
   move_packed(int(a[0])); continue_dispatch = node.chain
  "wait": m[0x92] = int(a[0])
  "write_block":
   var address := int(a[0])
   var page := int(a[1])*256
   for i in range(2,a.size()): m[page+address] = int(a[i]); address = (address+1)&255
   continue_dispatch = true
  "approach":
   m[0x92] = low
   for i in 2:
    var value := m[0xb0+i]
    var delta := (value-m[0x4d0+i]) & 255
    if delta >= 128: delta -= 256
    var amount := mini(absi(delta),m[0x4d2+i])
    m[0xb0+i] = (value + (amount if delta<0 else -amount)) & 255
   if m[0xb0] == m[0x4d0] and m[0xb1] == m[0x4d1]: m[0x93] = int(a[0])
  "call":
   m[0x9e] = m[0x94]; m[0x9f] = m[0x95]; m[0x9d] = m[0x93]
   set_pointer(int(a[0])+256*int(a[1])); m[0x93] = 0; continue_dispatch = true
  "return":
   m[0x94] = m[0x9e]; m[0x95] = m[0x9f]; m[0x93] = m[0x9d]; m[0x9f] = 0; continue_dispatch = true
  "speed_wait": m[0x92] = m[0x581]
  "clear_flag": m[0x97] = 0; continue_dispatch = true
  "set_flag": m[0x97] = 1; continue_dispatch = true
  "small_sprites": m[0x10] &= 223; m[0x80] = 8; continue_dispatch = true
  "large_sprites": m[0x10] |= 32; m[0x80] = 16; continue_dispatch = true
  "memory_branch","memory16_branch":
   var address := int(a[0]) + (256*int(a[1]) if op == "memory16_branch" else 0)
   if m[address] == int(a[-2]): m[0x93] = int(a[-1])
   continue_dispatch = true
  "clock":
   if int(a[0]) and not m[0x300]: m[0x300] = int(a[0])
   m[0x301] = (m[0x301] & 254) | (int(a[0]) ^ 1); m[0x306] = 100
  "sound":
   var value := int(a[0]) & 252
   m[0xf0+(int(a[0])&3)] = value if value&128 else value>>2
   continue_dispatch = true
  "contact_wait":
   var result := m[0x98]
   if result == 0: m[0x98] = 128
   if result == 0 or result & 128: m[0x93] = old_cursor
   else:
    if result != 3:
     var index := result-1 if result<3 else result-2
     m[0x93] = int(a[index])
    m[0x98] = 0; continue_dispatch = true
  "jump": set_pointer(int(a[0])+256*int(a[1])); m[0x93] = int(a[2]); continue_dispatch = true
  "loop":
   m[0x96] = (m[0x96]-1)&255
   if m[0x96]: m[0x93] = int(a[0])
   continue_dispatch = true
  "ready": m[0x90] = 129
  "set_loop": m[0x96] = int(a[0])
  "force": m[0xb4] = int(a[0]); m[0xb5] = int(a[1]); continue_dispatch = node.chain
  "defense":
   for i in 4: m[0xb6+i] = int(a[i])
   continue_dispatch = node.chain
  "release_player": m[0x53] = (m[0x53]+2)&255; m[0x52] = 1
  "write": m[int(a[0])] = int(a[1]); continue_dispatch = node.chain
  "lock_player": m[0x4a] = m[0x585]
  "wait_player":
   if m[0x4a]: m[0x93] = old_cursor
   else: continue_dispatch = true
  "player_hit_flag": m[0x5a] = int(a[0])
  "end": m[0x91] = 130
  "halt": m[0x93] = old_cursor; m[0x91] = 131
  _: error = "Invalid opponent command " + op

func dispatch() -> void:
 for iteration in 1000:
  command()
  if not error.is_empty() or not continue_dispatch: return
 error = "Opponent animation command budget exceeded"

func _apply_idle_guard(initial: bool) -> void:
 m[0x4ff] &= 127
 m[0xa1] = ((10 if initial else 130)-2*m[0x4ff]) & 255
 composition_requests.append([128,m[0xa1],0,m[0xb0],m[0xb1]])
 m[0xa0] = 0 # Source calls the compositor here synchronously.
 m[0xa2] = 0
 if initial: m[0xb2] = 240; m[0xb3] = 160
 m[0xb4] = 0; m[0xb5] = 0
 var defenses := [0,0,8,8,8,8,0,0]
 for i in 4: m[0xb6+i] = defenses[mini(m[0x4ff]*4+i,7)]

func _operand_at(address: int) -> int:
 for key in program.commands:
  var base := int(key)+1
  var args: Array = program.commands[key].arg
  if address >= base and address < base+args.size(): return int(args[address-base])
 error = "Unknown movement operand %04X" % address
 return 0

func step() -> void:
 composition_requests.clear()
 if m[0x90] == 0: return
 if m[0x90] & 128:
  m[0x90] &= 127; m[0x91] |= 128
  for address in range(0x92,0x9b): m[address] = 0
  for address in range(0xb4,0xba): m[address] = 0
  m[0x9c] = 1; m[0xaf] = 0; m[0x92] = 1; m[0x5a] = 0
  if not program.states.has(str(m[0x90])):
   error = "Unrecovered opponent state %d" % m[0x90]; return
  set_pointer(int(program.states[str(m[0x90])]))
  if m[0x90] == 1:
   m[0xba] = 0
   if m[0x5cc]: m[0x10] |= 32; m[0x80] = 16
   _apply_idle_guard(true)
   m[0x92] += 1
   dispatch()
   return
 if m[0x4a] != 0:
  m[0x4a] -= 1
  if m[0x4a] == 0: m[0x4b] = 0; m[0x4c] = 0
 m[0x92] = (m[0x92]-1)&255
 if m[0x92] != 0: return
 if m[0x90] == 1 and m[0x4ff] & 128: _apply_idle_guard(false)
 m[0x92] += 1
 if m[0xaf]:
  error = "Opponent script requested a non-first-fight program bank"; return
 if m[0x9a]:
  m[0x9a] -= 1; m[0x92] = m[0x9b]
  move_packed(_operand_at(pointer()+((m[0x93]-1)&255)))
  # Repetition reads the same packed operand and preserves its cursor.
  return
 dispatch()
