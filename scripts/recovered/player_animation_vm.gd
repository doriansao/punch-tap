extends RefCounted
## Semantic reimplementation of bank-11 animation VM, validated at its call boundary.
## No ROM, machine code, or Nintendo images are loaded by the game.
const PROGRAM_PATH := "res://assets/data/player_animation_program.json"
var program: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PROGRAM_PATH))
var m := PackedInt32Array()
var error := ""
var dispatched := 0
const HIGH_NAMES = ["pose","pose_scroll","scroll_delta","random_branch","pose_scroll_delta","wait","wait","wait","wait"]
const HIGH_LENGTHS = [1,2,1,1,2,1,1,1,1]
const EXT_NAMES = ["input_a_branch","input_b_branch","input_special_branch","memory_branch","held_guard","contact_target","clock","pose_accumulator_0","pose_accumulator_1","call","return","restore_health","sound","memory16_branch"]
const EXT_LENGTHS = [1,1,1,3,1,1,1,1,1,2,0,0,1,4]
const F_NAMES = ["contact_wait","jump","unlock","loop","ready","set_loop","force","defense","increment","invalid","write","effect_fixed","effect_tired","contact_flags","invalid","halt"]
const F_LENGTHS = [2,3,0,1,0,1,1,2,1,0,2,0,0,1,0,0]

func _init() -> void:
 m.resize(2048)

func load_ram(bytes: PackedByteArray) -> void:
 for i in mini(bytes.size(),2048): m[i] = bytes[i]
 error = ""

func _pointer() -> int: return m[0x54] + m[0x55] * 256
func _set_pointer(p: int) -> void:
 m[0x54] = p & 255
 m[0x55] = p >> 8
func _pose(value: int) -> void:
 m[0x61] = value
 m[0x60] = 128

func _node() -> Dictionary:
 var pc := _pointer() + m[0x53]
 if pc >= 2048:
  if program.commands.has(str(pc)): return program.commands[str(pc)]
  error = "Unrecovered player command at %04X" % pc
  return {}
 # Get-up scripts are constructed in RAM by the original count logic.
 var opcode := m[pc]
 var hi := opcode >> 4
 var lo := opcode & 15
 var name: String
 var count: int
 if hi < 9:
  name = HIGH_NAMES[hi]; count = HIGH_LENGTHS[hi]
 elif hi < 15 and lo < EXT_NAMES.size():
  name = EXT_NAMES[lo]; count = EXT_LENGTHS[lo]
 else:
  name = F_NAMES[lo]; count = F_LENGTHS[lo]
 var args: Array = []
 for i in count: args.append(m[pc + i + 1])
 var chained := name in ["force","defense","write"] and m[pc + count + 1] == 0
 return {"op":name,"arg":args,"duration":lo,"size":count+1+int(chained),"chain":chained}

func step() -> void:
 if m[0x50] == 0: return
 if m[0x50] & 128:
  m[0x50] &= 127; m[0x51] |= 128; m[0x52] = 1
  for address in [0x53,0x56,0x58,0x59,0x74,0x75,0x76,0x77]: m[address] = 0
  m[0x5b] = int(m[0x4a] != 0 and m[0x4b] != 0)
  if not program.states.has(str(m[0x50])):
   error = "Unrecovered player state %d" % m[0x50]; return
  _set_pointer(int(program.states[str(m[0x50])]))
 m[0x52] = (m[0x52] - 1) & 255
 if m[0x52] != 0: return
 m[0x52] = 1
 for iteration in 1000:
  var node := _node()
  if node.is_empty(): return
  dispatched += 1
  var op: String = node.op
  var a: Array = node.arg
  var old_cursor := m[0x53]
  m[0x53] = (old_cursor + int(node.size)) & 255
  match op:
   "pose":
    _pose(int(a[0])); m[0x52] = int(node.duration); return
   "pose_scroll":
    m[0x52] = int(node.duration); m[0x61] = int(a[0]); m[0x15] = int(a[1]); m[0x60] = 128; return
   "scroll_delta", "pose_scroll_delta":
    if op == "pose_scroll_delta": _pose(int(a[0]))
    m[0x52] = int(node.duration); m[0x15] = (m[0x15] + int(a[-1])) & 255; return
   "random_branch":
    var threshold := int(node.duration)
    var old_random := m[0x18]
    if threshold != 15:
     var carry := 0
     for bit in 3:
      var next_carry := m[0x18] & 1
      m[0x18] = (m[0x18] >> 1) | (carry << 7); carry = next_carry
    if threshold == 15 or threshold >= (old_random & 15) + 1: m[0x53] = int(a[0])
   "wait": m[0x52] = int(a[0]); return
   "input_a_branch", "input_b_branch", "input_special_branch":
    var mask := 9 if op == "input_a_branch" else (10 if op == "input_b_branch" else 4)
    if m[0xd3] & 128 and m[0xd2] & mask: m[0xd3] &= 127; m[0x53] = int(a[0])
   "memory_branch", "memory16_branch":
    var address := int(a[0]) + (256 * int(a[1]) if op == "memory16_branch" else 0)
    if m[address] == int(a[-2]): m[0x53] = int(a[-1])
   "held_guard":
    if m[0x6a] == 0:
     if not m[0xd3] & 129: m[0x6a] = 1
    elif m[0x6a] & 128:
     if not m[0xd3] & 129: m[0x50] = 129 if m[0xbc] else 130
    elif m[0xd3] & 128 and m[0xd2] & 4:
     m[0xd3] &= 127; m[0x50] = 14; m[0x53] = int(a[0]); continue
    return
   "contact_target": m[0x99] = 1; m[0x74] = int(a[0]); return
   "clock":
    if int(a[0]) != 0 and m[0x300] == 0: m[0x300] = int(a[0])
    m[0x301] = (m[0x301] & 254) | (int(a[0]) ^ 1); return
   "pose_accumulator_0", "pose_accumulator_1":
    var address := 0x70 if op == "pose_accumulator_0" else 0x71
    m[address] = (m[address] + int(a[0])) & 255; _pose(m[address]); return
   "call":
    m[0x7e] = m[0x54]; m[0x7f] = m[0x55]; m[0x7d] = m[0x53]
    _set_pointer(int(a[0])+256*int(a[1])); m[0x53] = 0
   "return": m[0x54] = m[0x7e]; m[0x55] = m[0x7f]; m[0x53] = m[0x7d]
   "restore_health": m[0x391] = m[0x397]; m[0x398] = m[0x39e]
   "sound":
    var value := int(a[0]) & 252
    m[0xf0 + (int(a[0]) & 3)] = value if value & 128 else value >> 2
   "contact_wait":
    var contact := m[0x58]
    if contact == 0: m[0x58] = 128 + int(m[0x5b] != 0)
    if contact == 0 or contact & 128: m[0x53] = old_cursor; return
    if contact in [1,2]: m[0x53] = int(a[contact-1])
    m[0x58] = 0
   "jump": _set_pointer(int(a[0])+256*int(a[1])); m[0x53] = int(a[2]); m[0x58] = 0
   "unlock": m[0x51] &= 127
   "loop":
    m[0x56] = (m[0x56]-1) & 255
    if m[0x56]: m[0x53] = int(a[0])
   "ready": m[0x50] = (130-m[0xbc]) & 255; return
   "set_loop": m[0x56] = int(a[0]); return
   "force", "defense", "write":
    if op == "force": m[0x75] = int(a[0])
    elif op == "defense": m[0x76] = int(a[0]); m[0x77] = int(a[1])
    else: m[int(a[0])] = int(a[1])
    if not node.get("chain",false): return
   "increment": m[int(a[0])] = (m[int(a[0])]+1) & 255
   "effect_fixed", "effect_tired":
    m[0x48d] = 48 if op == "effect_fixed" else m[0x4a1]
    m[0x48e] = 143 if op == "effect_fixed" or m[0xbc] else 20
    m[0x4a0] = 129
   "contact_flags": m[0x59] = int(a[0])
   "halt": m[0x53] = old_cursor; m[0x51] = 131; return
   _: error = "Invalid animation operation " + op; return
 error = "Player animation command budget exceeded"
