extends RefCounted
## Live actor interpreters, including high-picture referee commands.
## Two entrance gates remain measured overrides with unverified ownership.
const Machine = preload("res://scripts/recovered/animation_machine.gd")
var machine = Machine.new()
var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/entrance.json"))
var ticks := 0
var error := ""
var done := false
func _init() -> void:
	for address in data.initial: machine.m[int(address)] = int(data.initial[address])
	machine.opponent_picture = machine.opponent_compositor.compose(128,int(data.initial_selector),0,Vector2i(machine.m[0xb0],machine.m[0xb1]))
	machine.player_picture = machine.m[0x61]
	machine.present()
	machine.present()
func step() -> void:
	if done: return
	for gate in data.gates:
		if ticks == int(gate[0]): machine.m[int(gate[1])] = int(gate[2])
	machine.tick()
	ticks += 1
	error = machine.error
	done = ticks >= int(data.duration) or not error.is_empty()
func current(role: String) -> Dictionary:
	return machine.current(role)
