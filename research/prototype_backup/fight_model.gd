extends RefCounted
## Deterministic 60 Hz combat, independent of rendering and engine input.
signal event(kind: String, detail: String)
const PATTERNS = [
	{"name": "QUICK JAB", "safe": "right", "windup": 51, "damage": 14, "heavy": false},
	{"name": "SWITCH JAB", "safe": "left", "windup": 43, "damage": 14, "heavy": false},
	{"name": "POWER CROSS", "safe": "either", "windup": 66, "damage": 26, "heavy": true},
]
var active := false
var result := ""
var hp := 100
var opponent_hp := 100
var stamina := 100.0
var ticks := 0
var state := "ready"
var state_ticks := 78
var pattern_index := -1
var attack: Dictionary = PATTERNS[0]
var guard := false
var dodge := ""
var dodge_ticks := 0
var punch_cooldown := 0
var hit_stun := 0
var hits := 0
var counters := 0
var avoids := 0
var received := 0
var special_charge := 0

func start() -> void:
	active = true
	result = ""
	hp = 100
	opponent_hp = 100
	stamina = 100.0
	ticks = 0
	state = "ready"
	state_ticks = 78
	pattern_index = -1
	attack = PATTERNS[0]
	guard = false
	dodge = ""
	dodge_ticks = 0
	punch_cooldown = 0
	hit_stun = 0
	hits = 0
	counters = 0
	avoids = 0
	received = 0
	special_charge = 0
	event.emit("start", "READ. SLIP. COUNTER.")

func set_guard(value: bool) -> void:
	guard = value and active

func act(action: String, hand: String = "left") -> bool:
	if not active or hit_stun > 0:
		return false
	if action.begins_with("dodge_"):
		if dodge_ticks > 0 or stamina < 18.0:
			return false
		dodge = action.trim_prefix("dodge_")
		dodge_ticks = 25
		stamina -= 18.0
		event.emit("dodge", dodge)
		return true
	if action != "head" and action != "body" and action != "special":
		return false
	if punch_cooldown > 0 or dodge_ticks > 0 or guard:
		return false
	if action == "special" and special_charge < 3:
		event.emit("tired", "LAND 3 COUNTERS TO CHARGE SPECIAL")
		return false
	var cost := 20.0 if action == "special" else (14.0 if action == "head" else 10.0)
	if stamina < cost:
		event.emit("tired", "BREATHE — recover stamina")
		return false
	stamina -= cost
	punch_cooldown = 36 if action == "special" else (22 if action == "head" else 19)
	if action == "special": special_charge = 0
	event.emit("punch", hand + "_" + action)
	if state == "recovery":
		var damage := 32 if action == "special" else (12 if action == "head" else 9)
		opponent_hp = maxi(0, opponent_hp - damage)
		hits += 1
		counters += 1
		if action != "special": special_charge = mini(3, special_charge + 1)
		event.emit("counter", ("SPECIAL!  -%d" if action == "special" else "COUNTER!  -%d") % damage)
	elif state == "ready" and action == "body":
		opponent_hp = maxi(0, opponent_hp - 3)
		hits += 1
		event.emit("hit", "BODY SHOT  -3")
	else:
		event.emit("blocked", "GUARD UP — wait for an opening")
	if opponent_hp == 0:
		finish("win")
	return true

func step() -> void:
	if not active:
		return
	ticks += 1
	punch_cooldown = maxi(0, punch_cooldown - 1)
	hit_stun = maxi(0, hit_stun - 1)
	dodge_ticks = maxi(0, dodge_ticks - 1)
	if dodge_ticks == 0:
		dodge = ""
	if guard:
		stamina = maxf(0.0, stamina - 0.08)
	elif punch_cooldown == 0 and dodge_ticks == 0:
		stamina = minf(100.0, stamina + 0.34)
	state_ticks -= 1
	if state_ticks <= 0:
		match state:
			"ready":
				pattern_index = (pattern_index + 1) % PATTERNS.size()
				attack = PATTERNS[pattern_index]
				state = "windup"
				state_ticks = int(attack.windup)
				event.emit("tell", str(attack.name))
			"windup":
				state = "strike"
				state_ticks = 12
				resolve_strike()
			"strike":
				state = "recovery"
				state_ticks = 66 if bool(attack.heavy) else 51
				event.emit("opening", "OPEN!  LAND YOUR COUNTER")
			"recovery":
				state = "ready"
				state_ticks = 54
	if ticks >= 10800 and active:
		finish("win" if hp > opponent_hp else "loss")

func resolve_strike() -> void:
	if dodge_ticks > 0 and (attack.safe == "either" or dodge == attack.safe):
		avoids += 1
		event.emit("evade", "CLEAN SLIP!")
	elif guard and not bool(attack.heavy) and stamina >= 20.0:
		stamina -= 20.0
		avoids += 1
		event.emit("guard", "BLOCKED — now counter")
	else:
		var damage := int(attack.damage)
		hp = maxi(0, hp - damage)
		received += 1
		hit_stun = 15
		event.emit("hurt", "GUARD BREAK!" if guard and bool(attack.heavy) else "HIT!  -%d" % damage)
		if hp == 0:
			finish("loss")

func finish(outcome: String) -> void:
	active = false
	guard = false
	result = outcome
	event.emit("finish", outcome)
