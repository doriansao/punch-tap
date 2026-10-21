extends SceneTree
const Main = preload("res://scripts/main.gd")
var errors := 0

func check(ok: bool, message: String) -> void:
	if ok: print("PASS: ", message)
	else:
		errors += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var game = Main.new()
	root.add_child(game)
	game.sound_on = false
	game.set_physics_process(false)
	check(game.mode == "intro" and game.start_button.visible, "Intro exposes start button")
	game.start_button.pressed.emit()
	check(game.mode == "fight" and game.fight.active, "Start button enters fight")
	var key := InputEventKey.new()
	key.keycode = KEY_K
	key.pressed = true
	game._input(key)
	check(game.fight.opponent_hp == 97, "Keyboard body action reaches combat")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(124, 905)
	touch.pressed = true
	game._input(touch)
	check(game.fight.guard, "Joystick down holds guard")
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(124, 775)
	game._input(drag)
	check(not game.fight.guard and game.stick_direction == "up", "Joystick up releases guard and targets head")
	game.fight.punch_cooldown = 0
	game.fight.state = "recovery"
	var second := InputEventScreenTouch.new()
	second.index = 1
	second.position = Vector2(440, 880)
	second.pressed = true
	game._input(second)
	check(game.fight.opponent_hp == 85 and game.punch_side == 1.0 and game.punch_high, "Second finger right button throws right head punch")
	second.pressed = false
	game._input(second)
	check(game.stick_direction == "up", "Punch finger release leaves joystick held")
	touch.pressed = false
	game._input(touch)
	check(game.stick == Vector2.ZERO and not game.fight.guard, "Joystick release returns to neutral")
	game.fight.punch_cooldown = 0
	game.perform_action("left")
	check(game.fight.opponent_hp == 76 and game.punch_side == -1.0 and not game.punch_high, "Neutral left button throws left body punch")
	game._move_stick(Vector2(195, 839))
	var stamina_after_slip: float = game.fight.stamina
	game._move_stick(Vector2(195, 839))
	check(game.fight.dodge == "right" and game.fight.stamina == stamina_after_slip, "Holding joystick sideways does not spam slips")
	game._release_stick()
	game.toggle_pause()
	var ticks_before: int = game.fight.ticks
	game._physics_process(1.0 / 60.0)
	check(game.mode == "paused" and game.fight.ticks == ticks_before, "Pause freezes combat")
	game.start_button.pressed.emit()
	check(game.mode == "fight", "Resume restores fight")
	game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.mode == "paused" and not game.fight.guard, "Focus loss pauses and releases held inputs")
	game.start_button.pressed.emit()
	game.fight.finish("loss")
	check(game.mode == "result" and game.start_button.visible, "Defeat exposes rematch")
	game.start_button.pressed.emit()
	check(game.fight.hp == 100 and game.fight.opponent_hp == 100 and game.fight.ticks == 0, "Rematch restores fresh fight")
	for i in range(10801):
		var f = game.fight
		if f.state == "windup" and f.state_ticks == 12:
			game.perform_action("dodge_left" if f.attack.safe == "left" else "dodge_right")
		if f.state == "recovery" and f.punch_cooldown == 0: game.perform_action("head")
		game._physics_process(1.0 / 60.0)
		if not f.active: break
	check(game.mode == "result" and game.fight.result == "win", "Full counter fight reaches victory screen")
	game.queue_free()
	await process_frame
	print("UI TESTS: ", "PASS" if errors == 0 else "FAIL", " (", errors, " failures)")
	quit(0 if errors == 0 else 1)

