extends Control

const Fight = preload("res://scripts/fight_model.gd")
const INK = Color("101c2c")
const PAPER = Color("f6ebd5")
const MINT = Color("70f0c0")
const CORAL = Color("ff715d")
const MUTED = Color("90a9b5")
var fight = Fight.new()
var mode := "intro"
var clock := 0.0
var feedback := ""
var feedback_time := 0.0
var hit_flash := 0.0
var opponent_flash := 0.0
var punch_anim := 0.0
var punch_side := 1.0
var punch_high := false
var fighter_texture: Texture2D
var font: Font = ThemeDB.fallback_font
var actions: Array[Button] = []
var start_button: Button
var pause_button: Button
var sound_button: Button
var sound_on := true
var guard_sources: Dictionary = {}
var touches: Dictionary = {}
var tone_player: AudioStreamPlayer
var stick := Vector2.ZERO
var stick_finger := -1
var stick_direction := ""
var mouse_stick := false
var keyboard_high := false
const STICK_CENTER = Vector2(124, 839)
const STICK_RADIUS = 78.0


func _ready() -> void:
	fight.event.connect(_on_combat_event)
	if ResourceLoader.exists("res://assets/mara_sheet.png"):
		fighter_texture = load("res://assets/mara_sheet.png")
	start_button = make_button("ENTER THE RING  →", Rect2(48, 837, 444, 65), MINT)
	start_button.pressed.connect(_start_or_resume)
	pause_button = make_button("Ⅱ", Rect2(454, 24, 54, 44), Color("23374a"))
	pause_button.pressed.connect(toggle_pause)
	sound_button = make_button("SFX", Rect2(390, 24, 56, 44), Color("23374a"))
	sound_button.pressed.connect(func(): sound_on = not sound_on; sound_button.text = "SFX" if sound_on else "OFF")
	add_action("LEFT", Rect2(260, 833, 116, 88), CORAL, "left")
	add_action("RIGHT", Rect2(390, 833, 122, 88), CORAL, "right")
	add_action("SPECIAL  0/3", Rect2(282, 752, 230, 64), Color("edb875"), "special")
	tone_player = AudioStreamPlayer.new()
	add_child(tone_player)
	_update_buttons()
	print("PUNCH_TAP_FIGHT_READY")

func make_button(caption: String, rect: Rect2, color: Color) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", INK if color == MINT or color == CORAL or color == Color("edb875") else PAPER)
	for entry in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = color.lightened(0.12) if entry == "pressed" else color
		if entry == "disabled": style.bg_color = color.darkened(0.55)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.border_width_bottom = 4
		style.border_color = color.darkened(0.35)
		button.add_theme_stylebox_override(entry, style)
	add_child(button)
	return button

func add_action(caption: String, rect: Rect2, color: Color, action: String) -> void:
	var button := make_button(caption, rect, color)
	button.set_meta("combat_action", action)
	if action == "guard":
		button.button_down.connect(func(): _guard_source("mouse", true))
		button.button_up.connect(func(): _guard_source("mouse", false))
	else:
		button.button_down.connect(func(): perform_action(action))
	actions.append(button)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and mode == "fight":
			if event.position.distance_to(STICK_CENTER) <= 104 and stick_finger == -1:
				stick_finger = event.index
				_move_stick(event.position)
				get_viewport().set_input_as_handled()
				return
			for button in actions:
				if button.get_global_rect().has_point(event.position):
					touches[event.index] = button.get_meta("combat_action")
					perform_action(touches[event.index])
					get_viewport().set_input_as_handled()
					return
		elif event.index == stick_finger:
			_release_stick()
			get_viewport().set_input_as_handled()
		elif touches.has(event.index):
			touches.erase(event.index)
			get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag:
		if event.index == stick_finger:
			_move_stick(event.position)
			get_viewport().set_input_as_handled()
		elif touches.has(event.index): get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and mode == "fight" and event.position.distance_to(STICK_CENTER) <= 104:
			mouse_stick = true
			_move_stick(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and mouse_stick:
			_release_stick()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and mouse_stick:
		_move_stick(event.position)
		get_viewport().set_input_as_handled()
	if event is InputEventKey and not event.echo:
		if event.keycode == KEY_ESCAPE and event.pressed: toggle_pause()
		if event.keycode == KEY_ENTER and event.pressed and mode != "fight": _start_or_resume()
		if event.keycode == KEY_W or event.keycode == KEY_UP: keyboard_high = event.pressed and mode == "fight"
		if event.keycode == KEY_S or event.keycode == KEY_DOWN: _guard_source("keyboard", event.pressed)
		if event.pressed:
			match event.keycode:
				KEY_J: perform_action("left")
				KEY_K: perform_action("right")
				KEY_SPACE: perform_action("special")
				KEY_A, KEY_LEFT: perform_action("dodge_left")
				KEY_D, KEY_RIGHT: perform_action("dodge_right")

func _move_stick(point: Vector2) -> void:
	stick = ((point - STICK_CENTER) / STICK_RADIUS).limit_length(1.0)
	var direction := ""
	if stick.length() > 0.28:
		if absf(stick.x) > absf(stick.y): direction = "left" if stick.x < 0 else "right"
		else: direction = "up" if stick.y < 0 else "down"
	_guard_source("stick", direction == "down")
	if direction != stick_direction and (direction == "left" or direction == "right"):
		perform_action("dodge_" + direction)
	stick_direction = direction

func _release_stick() -> void:
	stick = Vector2.ZERO
	stick_direction = ""
	stick_finger = -1
	mouse_stick = false
	_guard_source("stick", false)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "fight":
		toggle_pause()

func _guard_source(source: String, pressed: bool) -> void:
	if pressed and mode == "fight": guard_sources[source] = true
	else: guard_sources.erase(source)
	fight.set_guard(not guard_sources.is_empty())

func perform_action(action: String) -> void:
	if mode != "fight": return
	if action == "left" or action == "right":
		fight.act("head" if stick_direction == "up" or keyboard_high else "body", action)
	else: fight.act(action)

func _start_or_resume() -> void:
	if mode == "paused":
		mode = "fight"
	else:
		fight.start()
		mode = "fight"
	_release_stick()
	keyboard_high = false
	guard_sources.clear()
	touches.clear()
	_update_buttons()

func toggle_pause() -> void:
	if mode == "fight": mode = "paused"
	elif mode == "paused": mode = "fight"
	else: return
	_release_stick()
	keyboard_high = false
	guard_sources.clear()
	touches.clear()
	fight.set_guard(false)
	_update_buttons()

func _update_buttons() -> void:
	for button in actions: button.visible = mode == "fight"
	start_button.visible = mode != "fight"
	pause_button.visible = mode == "fight" or mode == "paused"
	if mode == "intro":
		start_button.position = Vector2(48, 837)
		start_button.text = "ENTER THE RING  →"
	else:
		start_button.position = Vector2(48, 596)
		start_button.text = "RESUME FIGHT  →" if mode == "paused" else "REMATCH  ↻"

func _physics_process(_delta: float) -> void:
	if mode == "fight": fight.step()

func _process(delta: float) -> void:
	clock += delta
	feedback_time = maxf(0.0, feedback_time - delta)
	hit_flash = maxf(0.0, hit_flash - delta * 2.4)
	opponent_flash = maxf(0.0, opponent_flash - delta * 3.5)
	punch_anim = maxf(0.0, punch_anim - delta * 4.5)
	if actions.size() == 3:
		actions[2].text = "SPECIAL  READY" if fight.special_charge == 3 else "SPECIAL  %d/3" % fight.special_charge
	queue_redraw()

func _on_combat_event(kind: String, detail: String) -> void:
	if kind != "punch" and kind != "dodge":
		feedback = detail
		feedback_time = 1.0
	match kind:
		"punch":
			punch_side = -1.0 if detail.begins_with("left") else 1.0
			punch_anim = 1.0
			punch_high = detail.ends_with("head") or detail.ends_with("special")
			play_tone(160.0, 0.07, 0.15)
		"counter", "hit":
			opponent_flash = 0.7
			play_tone(85.0, 0.12, 0.3)
		"hurt":
			hit_flash = 0.8
			play_tone(55.0, 0.15, 0.4)
		"tell": play_tone(520.0 if not fight.attack.heavy else 260.0, 0.08, 0.1)
		"evade", "guard": play_tone(740.0, 0.07, 0.08)
		"finish":
			mode = "result"
			_release_stick()
			keyboard_high = false
			guard_sources.clear()
			touches.clear()
			_update_buttons()
			play_tone(660.0 if detail == "win" else 130.0, 0.4, 0.16)

func play_tone(frequency: float, duration: float, volume: float) -> void:
	if not sound_on or tone_player == null: return
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var samples := PackedByteArray()
	var count := int(duration * 22050)
	samples.resize(count * 2)
	for i in count:
		var t := float(i) / 22050.0
		var envelope := pow(1.0 - float(i) / float(count), 2.0)
		var value := sin(TAU * frequency * t * (1.0 - 0.25 * t / duration)) * envelope * volume
		samples.encode_s16(i * 2, int(value * 32767))
	audio.data = samples
	tone_player.stream = audio
	tone_player.play()

func panel(rect: Rect2, color: Color, radius := 12) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	draw_style_box(style, rect)

func text(value: String, at: Vector2, size_px: int, color := PAPER) -> void:
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, color)

func centered(value: String, y: float, size_px: int, color := PAPER) -> void:
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	text(value, Vector2((540.0 - width) / 2.0, y), size_px, color)

func bar(rect: Rect2, fraction: float, color: Color) -> void:
	panel(rect, Color("263847"), 3)
	if fraction > 0: panel(Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0, 1), rect.size.y)), color, 3)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 540, 960), INK)
	_draw_arena()
	_draw_opponent()
	_draw_gloves()
	# Header and two distinct health strips.
	draw_rect(Rect2(0, 0, 540, 176), INK)
	text("PUNCH", Vector2(28, 50), 30)
	text("TAP!", Vector2(145, 50), 30, CORAL)
	text("ROOFTOP CIRCUIT  /  BOUT 01", Vector2(29, 73), 11, MUTED)
	text("MARA ‘SWITCH’ VALE", Vector2(28, 107), 15, PAPER)
	text("%03d" % fight.opponent_hp, Vector2(470, 107), 16, CORAL)
	bar(Rect2(28, 119, 484, 10), float(fight.opponent_hp) / 100, CORAL)
	text("YOU", Vector2(28, 151), 13, MINT)
	bar(Rect2(77, 141, 182, 9), float(fight.hp) / 100, MINT)
	text("%03d" % fight.hp, Vector2(269, 152), 14, MINT)
	var remaining := maxi(0, 180 - int(fight.ticks / 60.0))
	text("R01  %d:%02d" % [int(remaining / 60.0), remaining % 60], Vector2(395, 152), 15, PAPER)
	# Action prompt is always readable above the opponent.
	if mode == "fight": _draw_cue()
	else:
		centered("THE NIGHT SHIFT", 205, 13, MINT)
		centered("ONE RING. YOUR MOMENT.", 228, 12, MUTED)
	if mode == "fight":
		panel(Rect2(18, 650, 504, 88), Color("152636"))
		centered(feedback if feedback_time > 0 else "Watch the tell. Slip late. Hit the opening.", 677, 17, MINT if opponent_flash > 0 else PAPER)
		text("STAMINA", Vector2(32, 706), 11, MUTED)
		bar(Rect2(111, 695, 342, 10), fight.stamina / 100.0, MINT if fight.stamina > 25 else CORAL)
		text("%d" % int(fight.stamina), Vector2(470, 707), 12, PAPER)
		text("COUNTERS  %02d" % fight.counters, Vector2(32, 725), 10, MUTED)
		text("CLEAN DEFENSE  %02d" % fight.avoids, Vector2(340, 725), 10, MUTED)
		draw_joystick()
		centered("UP + PUNCH: HEAD    •    DOWN: GUARD    •    SIDES: SLIP", 947, 10, MUTED)
	if hit_flash > 0:
		draw_rect(Rect2(0, 176, 540, 474), Color(1, 0.22, 0.15, hit_flash * 0.22))
	if mode == "intro": _draw_intro()
	elif mode == "paused" or mode == "result": _draw_overlay()

func _draw_arena() -> void:
	# Original geometric rooftop arena, kept separate from character assets.
	draw_rect(Rect2(0, 176, 540, 474), Color("1b3544"))
	draw_circle(Vector2(420, 268), 49, Color("e8c89a"))
	for i in range(12):
		var x := float(i * 49 - 20)
		var height := float(42 + (i * 37) % 115)
		draw_rect(Rect2(x, 429 - height, 42, height), Color("112737"))
		for j in range(3): draw_rect(Rect2(x + 9, 440 - height + j * 19, 4, 7), Color("3a5963"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 470), Vector2(540, 470), Vector2(540, 650), Vector2(0, 650)]), Color("335a60"))
	for x in range(-200, 800, 120): draw_line(Vector2(x, 650), Vector2(270 + (x - 270) * 0.5, 470), Color("40686a"), 1)
	for y in [491, 530, 586]: draw_line(Vector2(0, y), Vector2(540, y), Color("40686a"), 1)
	for y in [399, 431, 467]:
		draw_line(Vector2(0, y + 9), Vector2(540, y - 9), Color("0b202d"), 7)
		draw_line(Vector2(0, y + 6), Vector2(540, y - 12), CORAL if y == 399 else Color("809a96"), 3)
	text("NIGHT / SHIFT", Vector2(22, 348), 11, MUTED)
	draw_arc(Vector2(270, 578), 112, 0, TAU, 64, Color("547978"), 2)
	draw_line(Vector2(0, 636), Vector2(540, 636), Color("0e2632"), 13)
	draw_line(Vector2(0, 630), Vector2(540, 630), MINT.darkened(0.35), 4)

func _draw_opponent() -> void:
	if fighter_texture == null: return
	var frame := 0
	var bob := sin(clock * 3.6) * 3.0
	var offset := Vector2(0, bob)
	if fight.state == "windup" and mode != "intro":
		frame = 3 if fight.attack.heavy else 1
		offset.x = sin(clock * 17) * 2
	elif fight.state == "strike":
		frame = 2
		offset.y = 12
	elif fight.state == "recovery": frame = 0
	if opponent_flash > 0: frame = 4
	if fight.result == "win": frame = 5
	var region_size := Vector2(fighter_texture.get_width() / 3.0, fighter_texture.get_height() / 2.0)
	var region := Rect2(Vector2(frame % 3, int(frame / 3.0)) * region_size, region_size)
	# Sprite sheet cells are square; preserve that aspect in the game.
	var rect := Rect2(Vector2(50, 244) + offset, Vector2(440, 390))
	rect.size.x = rect.size.y * region_size.x / region_size.y
	rect.position.x = (540.0 - rect.size.x) / 2 + offset.x
	draw_set_transform(Vector2(270, 597), 0, Vector2(1, 0.18))
	draw_circle(Vector2.ZERO, 80, Color(0.02, 0.08, 0.12, 0.45))
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect_region(fighter_texture, rect, region, Color(1.0, 1.0 - opponent_flash * 0.35, 1.0 - opponent_flash * 0.35))

func _draw_gloves() -> void:
	if mode == "intro" or mode == "result": return
	var shift := -64.0 if fight.dodge == "left" else (64.0 if fight.dodge == "right" else 0.0)
	for side in [-1.0, 1.0]:
		var at := Vector2(270 + side * 138 + shift, 609)
		if fight.guard: at = Vector2(270 + side * 56, 546)
		if punch_anim > 0 and side == punch_side:
			at = at.lerp(Vector2(270 + side * 20, 425 if punch_high else 520), sin(punch_anim * PI))
		draw_set_transform(at, side * 0.13)
		panel(Rect2(-34, 14, 68, 60), Color("bacfc4"), 10)
		panel(Rect2(-44, -40, 88, 84), Color("081e2a"), 27)
		panel(Rect2(-39, -37, 78, 74), MINT.darkened(0.12), 24)
		panel(Rect2(-30, -29, 56, 22), MINT, 10)
		draw_line(Vector2(-25, 19), Vector2(25, 19), Color("318978"), 3)
		draw_set_transform(Vector2.ZERO)

func _draw_cue() -> void:
	var title := "READ THE GUARD"
	var subtitle := "Body shots chip. Jabs need an opening."
	var color := MUTED
	if fight.state == "windup":
		title = str(fight.attack.name)
		color = CORAL if fight.attack.heavy else PAPER
		subtitle = "UNBLOCKABLE · SLIP EITHER WAY" if fight.attack.heavy else ("SLIP RIGHT →  OR HOLD GUARD" if fight.attack.safe == "right" else "← SLIP LEFT  OR HOLD GUARD")
		var progress := 1.0 - float(fight.state_ticks) / float(fight.attack.windup)
		bar(Rect2(100, 239, 340, 5), progress, CORAL)
	elif fight.state == "recovery":
		title = "COUNTER WINDOW"
		subtitle = "JAB NOW · BONUS DAMAGE"
		color = MINT
	elif fight.state == "strike":
		title = "SLIP!"
		subtitle = ""
		color = CORAL
	centered(title, 202, 18, color)
	centered(subtitle, 226, 12, color)

func _draw_intro() -> void:
	panel(Rect2(18, 624, 504, 300), Color("142433"), 18)
	text("YOUR FIRST CHALLENGER", Vector2(40, 653), 11, MINT)
	text("MARA ‘SWITCH’ VALE", Vector2(40, 686), 26, PAPER)
	text("A quick jab. A late cross. Never the same rhythm.", Vector2(40, 711), 14, MUTED)
	text("01   Watch the cue. Slip as the bar fills.", Vector2(40, 746), 16)
	text("02   Stick up: head. Down: guard. Sides: slip.", Vector2(40, 776), 16)
	text("03   Left / right punch. 3 counters earn special.", Vector2(40, 806), 16)
	centered("ORIGINAL FIGHTERS  /  ORIGINAL RULES  /  FIRST PLAYABLE", 947, 9, MUTED)

func _draw_overlay() -> void:
	draw_rect(Rect2(0, 176, 540, 784), Color(0.025, 0.05, 0.08, 0.86))
	panel(Rect2(24, 316, 492, 371), Color("1b3040"), 18)
	var win: bool = fight.result == "win"
	centered("TAKE A BREATH" if mode == "paused" else ("YOU OWN THE RING" if win else "BACK TO THE GYM"), 356, 12, MINT)
	centered("PAUSED" if mode == "paused" else ("VICTORY!" if win else ("KNOCKED OUT" if fight.hp == 0 else "OUTPOINTED")), 412, 39, PAPER if mode == "paused" else (MINT if win else CORAL))
	if mode == "paused":
		centered("Your fight is waiting.", 467, 20)
		centered("J / K fists · W head · S guard · A / D slip", 506, 15, MUTED)
		centered("Space: special · Escape: pause · SFX: sound", 536, 15, MUTED)
	else:
		centered(("Mara takes a knee. A new contender rises." if fight.opponent_hp == 0 else "The bell rings. You win on remaining health.") if win else "Time your slip just before the strike.", 455, 16, MUTED)
		centered("%d COUNTERS     %d CLEAN DEFENSES" % [fight.counters, fight.avoids], 500, 17)
		centered("%d:%02d elapsed  ·  %d hits taken" % [int(fight.ticks / 3600.0), (int(fight.ticks / 60.0)) % 60, fight.received], 535, 15, MUTED)
		centered("Try another round. Learn the rhythm.", 565, 14, MUTED)



func draw_joystick() -> void:
	draw_circle(STICK_CENTER, 84, Color("0a1522"))
	draw_circle(STICK_CENTER, 77, Color("263f50"))
	draw_arc(STICK_CENTER, 77, 0, TAU, 64, Color("557282"), 2)
	draw_line(STICK_CENTER + Vector2(-54, 0), STICK_CENTER + Vector2(54, 0), Color("365363"), 1)
	draw_line(STICK_CENTER + Vector2(0, -54), STICK_CENTER + Vector2(0, 54), Color("365363"), 1)
	text("HEAD", STICK_CENTER + Vector2(-16, -57), 10, MINT)
	text("GUARD", STICK_CENTER + Vector2(-22, 66), 10, MINT)
	text("‹", STICK_CENTER + Vector2(-69, 6), 24, PAPER)
	text("›", STICK_CENTER + Vector2(57, 6), 24, PAPER)
	draw_circle(STICK_CENTER + stick * 44, 29, MINT if stick.length() > 0.28 else Color("789ca5"))
	draw_circle(STICK_CENTER + stick * 44, 21, Color("426c73"))
