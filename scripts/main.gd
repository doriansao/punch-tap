extends Control

const Opponent = preload("res://scripts/opponent_identity.gd")
const Fight = preload("res://scripts/fight_model_vm.gd")
const AnimationTimeline = preload("res://scripts/recovered/animation_timeline.gd")
var animation_timeline = AnimationTimeline.new()
var art_registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/art_registration.json"))
var show_animation_measurements := false
var recovered_textures: Dictionary = {}
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
var block_flash := 0.0
var punch_anim := 0.0
var punch_side := 1.0
var punch_high := false
var fighter_texture: Texture2D
var player_texture: Texture2D
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
	if ResourceLoader.exists(Opponent.SPRITE_PATH):
		fighter_texture = load(Opponent.SPRITE_PATH)
	if ResourceLoader.exists("res://assets/teo_rear.png"):
		player_texture = load("res://assets/teo_rear.png")
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
		button.button_up.connect(func(): fight.release(action))
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
			fight.release(touches[event.index])
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
		if not event.pressed:
			match event.keycode:
				KEY_J: fight.release("left")
				KEY_K: fight.release("right")
				KEY_SPACE: fight.release("special")
				KEY_A, KEY_LEFT: fight.release("dodge_left")
				KEY_D, KEY_RIGHT: fight.release("dodge_right")
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
	if direction != stick_direction and stick_direction in ["left", "right"]:
		fight.release("dodge_" + stick_direction)
	_guard_source("stick", direction == "down")
	if direction != stick_direction and (direction == "left" or direction == "right"):
		perform_action("dodge_" + direction)
	stick_direction = direction

func _release_stick() -> void:
	fight.release("dodge_left")
	fight.release("dodge_right")
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
		hit_flash = 0
		opponent_flash = 0
		block_flash = 0
		punch_anim = 0
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
	fight.release_all()
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
	if mode == "fight":
		fight.aim_high = keyboard_high or stick_direction == "up"
		fight.step()

func _process(delta: float) -> void:
	clock += delta
	feedback_time = maxf(0.0, feedback_time - delta)
	hit_flash = maxf(0.0, hit_flash - delta * 2.4)
	opponent_flash = maxf(0.0, opponent_flash - delta * 3.5)
	block_flash = maxf(0.0, block_flash - delta)
	punch_anim = maxf(0.0, punch_anim - delta * 4.5)
	if actions.size() == 3:
		actions[2].text = "SPECIAL  ★ %d" % fight.stars if fight.stars > 0 else "SPECIAL  ☆"
	queue_redraw()

func _on_combat_event(kind: String, detail: String) -> void:
	animation_timeline.event(kind, fight)
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
		"blocked": block_flash = 0.25
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
	_draw_player()
	# Header and two distinct health strips.
	draw_rect(Rect2(0, 0, 540, 176), INK)
	text("PUNCH", Vector2(28, 50), 30)
	text("TAP!", Vector2(145, 50), 30, CORAL)
	text("ROOFTOP CIRCUIT  /  BOUT 01", Vector2(29, 73), 11, MUTED)
	text(Opponent.NAME.to_upper(), Vector2(28, 107), 15, PAPER)
	text("%03d" % fight.opponent_hp, Vector2(470, 107), 16, CORAL)
	bar(Rect2(28, 119, 484, 10), float(fight.opponent_hp) / 96, CORAL)
	text("YOU", Vector2(28, 151), 13, MINT)
	bar(Rect2(77, 141, 182, 9), float(fight.hp) / 96, MINT)
	text("%03d" % fight.hp, Vector2(269, 152), 14, MINT)
	var remaining := int(fight.round_centis / 100.0)
	text("R%d  %d:%02d" % [fight.round_number, int(remaining / 60.0), remaining % 60], Vector2(395, 152), 15, PAPER)
	# Action prompt is always readable above the opponent.
	if mode == "fight": _draw_cue()
	else:
		centered("THE NIGHT SHIFT", 205, 13, MINT)
		centered("ONE RING. YOUR MOMENT.", 228, 12, MUTED)
	if mode == "fight":
		panel(Rect2(18, 650, 504, 88), Color("152636"))
		centered(feedback if feedback_time > 0 else "Aim high. Read the guard. Save your stars.", 677, 17, MINT if opponent_flash > 0 else PAPER)
		text("HEARTS", Vector2(32, 706), 11, MUTED)
		bar(Rect2(111, 695, 342, 10), float(fight.hearts) / 20.0, MINT if fight.hearts > 0 else CORAL)
		text("%d" % fight.hearts, Vector2(470, 707), 12, PAPER)
		text("SCORE  %06d" % fight.points, Vector2(32, 725), 10, MUTED)
		text("DOWNS  YOU %d/3  •  NICO %d/3" % [fight.player_downs, fight.opponent_downs], Vector2(275, 725), 10, MUTED)
		draw_joystick()
		centered("UP + PUNCH: HEAD    •    DOWN: GUARD    •    SIDES: SLIP", 947, 10, MUTED)
	if hit_flash > 0:
		draw_rect(Rect2(0, 176, 540, 474), Color(1, 0.22, 0.15, hit_flash * 0.22))
	if mode == "intro": _draw_intro()
	elif mode == "paused" or mode == "result": _draw_overlay()

func _draw_arena() -> void:
	# The NES fight floor begins immediately beneath the far ropes. Keep the
	# recovered on-canvas knockdown coordinates on our canvas as well.
	draw_rect(Rect2(0,176,540,474),Color("1b3544"))
	draw_circle(Vector2(420,222),28,Color("e8c89a"))
	for i in range(12):
		var x := float(i*49-20)
		var height := float(15+(i*17)%48)
		draw_rect(Rect2(x,254-height,42,height),Color("112737"))
	draw_rect(Rect2(0,264,540,386),Color("335a60"))
	for x in range(-240,840,120):
		draw_line(Vector2(x,650),Vector2(270+(x-270)*0.35,264),Color("40686a"),1)
	for y in [294,342,402,482,584]:
		draw_line(Vector2(0,y),Vector2(540,y),Color("40686a"),1)
	for y in [232,248,264]:
		draw_line(Vector2(0,y+4),Vector2(540,y-4),Color("0b202d"),6)
		draw_line(Vector2(0,y+2),Vector2(540,y-6),CORAL if y==232 else Color("809a96"),3)
	draw_arc(Vector2(270,494),112,0,TAU,64,Color("547978"),2)
	draw_line(Vector2(0,636),Vector2(540,636),Color("0e2632"),13)
	draw_line(Vector2(0,630),Vector2(540,630),MINT.darkened(0.35),4)

# Uniform NES-to-portrait transform. All motion below comes from sampled data.
const SOURCE_SCALE := 2.6
func source_point(p: Vector2) -> Vector2:
	return Vector2(270, 256) + (p - Vector2(132, 89)) * SOURCE_SCALE

func _draw_opponent() -> void: _draw_measured_actor("opponent", fighter_texture)
func _draw_player() -> void: _draw_measured_actor("player", player_texture)

func _art_pose(row: Dictionary, _role: String) -> int:
	return int(row.get("art_frame", 24))

func _draw_measured_actor(role: String, texture: Texture2D) -> void:
	if texture == null: return
	var row: Dictionary = animation_timeline.current(fight, role)
	if row.box.is_empty(): return
	var b: Array = row.box
	var box := Rect2(source_point(Vector2(b[0], b[1])), Vector2(b[2], b[3]) * SOURCE_SCALE)
	var pose := _art_pose(row, role)
	var registration: Dictionary = art_registration[role][pose]
	var path: String = registration.texture
	if not recovered_textures.has(path): recovered_textures[path] = load(path)
	texture = recovered_textures[path]
	var r: Array = registration.region
	var region := Rect2(r[0],r[1],r[2],r[3])
	var full: Array = row.get("draw_box",b)
	# Original body proportions stay intact. Use recovered vertical extent,
	# centre and clipping; never squeeze the torso to a changing mask width.
	var art_scale := float(full[3]) * SOURCE_SCALE / region.size.y
	var art_width := region.size.x * art_scale
	# Offscreen bodies must be cropped, not shrunk. Extent is restored only
	# where a full observed source silhouette exactly matches the visible part.
	if row.has("crop_y"):
		region.position.y += region.size.y * float(row.crop_y[0])
		region.size.y *= float(row.crop_y[1])
	var flip: bool = bool(row.get("art_flip", false))
	# Select the pose from the displayed PPU/OAM composition. Particle islands
	# are separate so they cannot stretch the boxer when an impact appears.
	var anchor := source_point(Vector2(float(full[0])+float(full[2])/2,float(b[1])))
	draw_set_transform(anchor, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect_region(texture, Rect2(Vector2(-art_width/2,0),Vector2(art_width,region.size.y*art_scale)),region)
	draw_set_transform(Vector2.ZERO)
	for effect in row.get("effects", []):
		var center := source_point(Vector2(effect[0],effect[1]))
		var radius := clampf(sqrt(float(effect[2])) * SOURCE_SCALE * 0.25, 1.0, 4.0)
		draw_circle(center, radius, PAPER)
	if show_animation_measurements:
		draw_rect(box, MINT if role == "player" else CORAL, false, 1)
		if not row.tip.is_empty():
			var target := source_point(Vector2(row.tip[0],row.tip[1]))
			draw_line(target-Vector2(4,0),target+Vector2(4,0),Color.YELLOW,2)
			draw_line(target-Vector2(0,4),target+Vector2(0,4),Color.YELLOW,2)

func _draw_cue() -> void:
	var title := "READ THE GUARD"
	var subtitle := "Head shots score. Body shots need an opening."
	var color := MUTED
	match fight.state:
		"windup":
			title = str(fight.attack.name)
			subtitle = "SLIP EITHER WAY  •  DOWN TO BLOCK"
			color = CORAL
			bar(Rect2(100, 239, 340, 5), 1.0 - float(fight.state_ticks) / maxf(1, float(fight.attack.windup)), CORAL)
		"strike": title = "SLIP!"; subtitle = ""; color = CORAL
		"recovery": title = "COUNTER NOW"; subtitle = "A brief opening"; color = MINT
		"taunt": title = "WAIT FOR THE RETURN"; subtitle = "He is out of reach"
		"opening": title = "CHIN OPEN!"; subtitle = "Time a clean punch"; color = MINT
		"opponent_down":
			title = "%d" % fight.count if fight.count > 0 else "KNOCKDOWN!"
			subtitle = Opponent.SHORT_NAME + " MUST BEAT THE COUNT"
		"player_down":
			title = "%d" % fight.count if fight.count > 0 else "YOU ARE DOWN"
			subtitle = "TAP LEFT / RIGHT TO GET UP"; color = CORAL
		"countout": title = "TKO"; subtitle = "Three knockdowns in the round"
		"between_rounds": title = "ROUND OVER"; subtitle = "TAP A PUNCH TO CONTINUE"
	centered(title, 202, 18, color)
	centered(subtitle, 226, 12, color)

func _draw_intro() -> void:
	panel(Rect2(18, 624, 504, 300), Color("142433"), 18)
	text("YOUR FIRST CHALLENGER", Vector2(40, 653), 11, MINT)
	text(Opponent.NAME.to_upper(), Vector2(40, 686), 26, PAPER)
	text("Keep your guard. Catch him on the way back.", Vector2(40, 711), 14, MUTED)
	text("01   Aim high. Watch his guard and footwork.", Vector2(40, 746), 16)
	text("02   Stick up: head. Down: guard. Sides: slip.", Vector2(40, 776), 16)
	text("03   Earn stars. One star powers an uppercut.", Vector2(40, 806), 16)
	centered("ORIGINAL FIGHTERS  /  ROOFTOP CIRCUIT  /  BOUT ONE", 947, 9, MUTED)

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
		centered(("Nico takes a knee. A new contender rises." if fight.opponent_hp == 0 else "The judges award you the bout.") if win else "Time your slip just before the strike.", 455, 16, MUTED)
		centered("%d COUNTERS     %d CLEAN DEFENSES" % [fight.counters, fight.avoids], 500, 17)
		centered("%d:%02d elapsed  ·  %d hits taken" % [int(fight.ticks / 3600.0), (int(fight.ticks / 60.0)) % 60, fight.received], 535, 15, MUTED)
		centered("%s  •  %d POINTS" % [fight.verdict, fight.points], 565, 14, MUTED)



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
