extends RefCounted
## Bank 7 $8A6F control flow. Keep RNG/timers even though Godot replaces the HUD.
## Original message strings, glyph tiles and graphics are not included.
static var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/presentation_control.json"))
static func rotate_random(m: PackedInt32Array, carry: int) -> void:
	for i in 3:
		var next := m[0x18] & 1
		m[0x18] = (m[0x18] >> 1) | (carry << 7)
		carry = next
static func chance(m: PackedInt32Array, threshold: int) -> bool:
	if threshold == 15: return true
	var value := m[0x18]
	rotate_random(m, 0)
	return threshold > (value & 15)
static func step(m: PackedInt32Array) -> PackedInt32Array:
	if m[0x40] & 128:
		if m[0x1e] & 15: return m
		m[0x40] &= 127
		m[0x41] = 128; m[0x42] = 1; m[0x43] = 0
		var pointer: int = data.initial.get(str(m[0x40]), 0)
		assert(pointer != 0, "Unknown presentation program")
		m[0x44] = pointer & 255; m[0x45] = pointer >> 8
	if m[0x40] == 0 or m[0x46] != 0: return m
	if m[0x40] == 3 and (m[0x1e] & 15) == 0: m[0x40] = 4
	if m[0x410] & 128: return m
	m[0x42] = (m[0x42] - 1) & 255
	if m[0x42] != 0: return m
	m[0x42] = 1
	var base := m[0x44] + 256 * m[0x45]
	for budget in 64:
		var pc := base + m[0x43]
		assert(data.commands.has(str(pc)), "Unknown presentation command %04X" % pc)
		var node: Dictionary = data.commands[str(pc)]
		m[0x43] = (int(node.next) - base) & 255
		match node.op:
			"branch":
				if chance(m, int(node.value)): m[0x43] = int(node.operand)
			"choose", "choose_alt":
				rotate_random(m, 0)
				return m
			"wait":
				m[0x42] = (int(node.operand) & 15) if chance(m, int(node.value)) else (int(node.operand) >> 4)
				return m
			"draw", "draw_alt":
				# A queued source transfer is acknowledged before the next update.
				m[0x410] = 129
				return m
	assert(false, "Presentation command budget exceeded")
	return m
