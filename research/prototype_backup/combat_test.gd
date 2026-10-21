extends SceneTree
const Fight = preload("res://scripts/fight_model.gd")
var failures := 0

func check(ok: bool, description: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: ", description)
	else: print("PASS: ", description)

func _initialize() -> void:
	var f = Fight.new()
	f.start()
	f.act("head")
	check(f.opponent_hp == 100, "Raised guard blocks premature head shots")
	check(not f.act("head"), "Punch cooldown prevents spam")
	f.start()
	f.act("body")
	check(f.opponent_hp == 97, "Body shot chips idle guard")
	f.start()
	f.state = "recovery"
	f.act("head")
	check(f.opponent_hp == 88 and f.counters == 1, "Open counter deals bonus damage")
	f.stamina = 0
	f.punch_cooldown = 0
	check(not f.act("head") and not f.act("dodge_left"), "Stamina gates attacks and slips")
	f.start()
	f.attack = Fight.PATTERNS[0]
	f.act("dodge_right")
	f.resolve_strike()
	check(f.hp == 100 and f.avoids == 1, "Correct slip avoids jab")
	f.start()
	f.act("dodge_left")
	f.resolve_strike()
	check(f.hp == 86, "Wrong slip takes jab damage")
	f.start()
	f.set_guard(true)
	f.resolve_strike()
	check(f.hp == 100 and f.stamina == 80, "Guard trades stamina for protection")
	f.attack = Fight.PATTERNS[2]
	f.resolve_strike()
	check(f.hp == 74, "Heavy cross breaks guard")
	f.start()
	f.set_guard(true)
	f.stamina = 19
	f.resolve_strike()
	check(f.hp == 86, "Exhausted guard cannot block")
	f.start()
	for i in range(2400): f.step()
	check(f.result == "loss", "Passive player reaches defeat")
	var frozen_ticks: int = f.ticks
	f.step()
	check(f.ticks == frozen_ticks and not f.act("head"), "Finished fight cannot keep advancing")
	f.start()
	check(f.hp == 100 and f.opponent_hp == 100 and f.ticks == 0 and f.counters == 0, "Rematch resets all fight stats")
	var a = play_counter_strategy()
	var special = Fight.new()
	special.start()
	check(not special.act("special"), "Special requires a full charge")
	special.state = "recovery"
	for i in 3:
		special.punch_cooldown = 0
		special.act("head", "right")
	check(special.special_charge == 3, "Three counters charge the special")
	special.punch_cooldown = 0
	special.act("special")
	check(special.opponent_hp == 32 and special.special_charge == 0, "Special consumes charge and deals 32 opening damage")
	special.start()
	check(special.special_charge == 0, "Rematch clears special charge")
	var b = play_counter_strategy()
	check(a.result == "win" and a.hp == 100, "Readable pattern can be beaten without taking damage")
	check(a.ticks == b.ticks and a.counters == b.counters and a.stamina == b.stamina, "Identical input strategy produces deterministic outcome")
	print("COMBAT TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)

func play_counter_strategy():
	var f = Fight.new()
	f.start()
	for i in range(10801):
		if f.state == "windup" and f.state_ticks == 12:
			f.act("dodge_left" if f.attack.safe == "left" else "dodge_right")
		if f.state == "recovery" and f.punch_cooldown == 0:
			f.act("head")
		f.step()
		if not f.active: break
	return f
