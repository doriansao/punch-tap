extends Control

const Opponent = preload("res://scripts/opponent_identity.gd")
const Fight = preload("res://scripts/fight_model_vm.gd")
const AnimationTimeline = preload("res://scripts/recovered/animation_timeline.gd")
var animation_timeline = AnimationTimeline.new()
var entrance
var referee_texture: Texture2D=preload("res://assets/cartoon/production/referee_v1.png")
var referee_art: Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/referee_art.json"))
var isolated_sprite = preload("res://scripts/isolated_sprite.gd").new()
var interface = preload("res://scripts/illustrated_interface.gd").new()
var ringside = preload("res://scripts/ringside_presentation.gd").new()
var art_registration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/art_registration.json"))
var show_animation_measurements := false
var recovered_textures: Dictionary = {}
var contact_glove_draw: Dictionary = {}
const INK = Color("101c2c")
const PAPER = Color("f6ebd5")
const MINT = Color("70f0c0")
const CORAL = Color("ff715d")
const MUTED = Color("90a9b5")
var fight = Fight.new()
var title_view = preload("res://scripts/title_presentation.gd").new()
var mode := "intro"
var pause_origin := "fight"
var clock := 0.0
var feedback := ""
var pending_impacts: Array = []
var pending_attack_cue:=false
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
var controller=preload("res://scripts/controller_input.gd").new()
var controller_state:Dictionary={}
const STICK_CENTER = Vector2(124, 839)
const STICK_RADIUS = 78.0


func _ready() -> void:
	fight.event.connect(_on_combat_event)
	Input.joy_connection_changed.connect(_controller_connection_changed)
	if ResourceLoader.exists(Opponent.SPRITE_PATH):
		fighter_texture = load(Opponent.SPRITE_PATH)
	if ResourceLoader.exists("res://assets/cartoon/production/teo_stances.png"):
		player_texture = load("res://assets/cartoon/production/teo_stances.png")
	start_button = make_button("ENTER THE RING  >", Rect2(48, 837, 444, 65), MINT)
	start_button.pressed.connect(func():
		if mode in ["intro", "result"]: _begin_entrance()
		elif mode == "paused": _start_or_resume())
	pause_button = make_button("II", Rect2(454, 24, 54, 44), Color("23374a"))
	pause_button.pressed.connect(toggle_pause)
	sound_button = make_button("SFX", Rect2(390, 24, 56, 44), Color("23374a"))
	sound_button.pressed.connect(func(): sound_on = not sound_on; sound_button.text = "SFX" if sound_on else "OFF")
	add_action("LEFT\nPUNCH", Rect2(254, 818, 122, 122), CORAL, "left")
	add_action("RIGHT\nPUNCH", Rect2(386, 818, 122, 122), CORAL, "right")
	add_action("SPECIAL  0/3", Rect2(398, 708, 96, 96), Color("edb875"), "special")
	interface.skin(actions[0],"left","Left punch  /  J")
	interface.skin(actions[1],"right","Right punch  /  K")
	interface.skin(actions[2],"special","Star uppercut  /  Space")
	interface.skin(pause_button,"pause","Pause  /  Escape")
	pause_button.position=Vector2(478,20)
	pause_button.size=Vector2(42,42)
	sound_button.hide()
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
		style.corner_radius_top_left = 30
		style.corner_radius_top_right = 24
		style.corner_radius_bottom_left = 24
		style.corner_radius_bottom_right = 30
		style.set_border_width_all(4)
		style.border_width_bottom = 7
		style.border_color = INK
		style.shadow_color = Color(0,0,0,0.35)
		style.shadow_size = 3
		style.shadow_offset = Vector2(0,4)
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
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_controller_event(event)
		get_viewport().set_input_as_handled()
		return
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
		if event.keycode == KEY_ENTER and event.pressed:
			if mode in ["intro","result"]: _begin_entrance()
			elif mode == "paused": _start_or_resume()
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

func _controller_event(event:InputEvent)->void:
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index==JOY_BUTTON_START:
			if mode in ["intro","result"]:_begin_entrance()
			else:toggle_pause()
			return
		if event.button_index==JOY_BUTTON_A and mode in ["intro","result","paused"]:
			if mode=="paused":_start_or_resume()
			else:_begin_entrance()
			return
	if mode!="fight" or not controller.feed(event):return
	var previous:=controller_state
	controller_state=controller.snapshot()
	_guard_source("controller",controller_state.guard)
	for action in ["left","right","special","dodge_left","dodge_right"]:
		if controller_state[action] and not previous.get(action,false):perform_action(action)
		elif not controller_state[action] and previous.get(action,false):fight.release(action)

func _reset_controller()->void:
	controller.reset();controller_state.clear()
	_guard_source("controller",false)

func _controller_connection_changed(device:int,connected:bool)->void:
	if not connected and device==controller.device:
		if mode=="fight":toggle_pause()
		else:_reset_controller()

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
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode in ["fight","entrance"]:
		toggle_pause()

func _guard_source(source: String, pressed: bool) -> void:
	if pressed and mode == "fight": guard_sources[source] = true
	else: guard_sources.erase(source)
	fight.set_guard(not guard_sources.is_empty())

func perform_action(action: String) -> void:
	if mode != "fight": return
	if action == "left" or action == "right":
		fight.act("head" if stick_direction == "up" or keyboard_high or controller_state.get("high",false) else "body", action)
	else: fight.act(action)

func _begin_entrance() -> void:
	_reset_controller()
	entrance = preload("res://scripts/recovered/fight_entrance.gd").new()
	mode = "entrance"
	_update_buttons()

func _start_or_resume() -> void:
	if mode == "paused":
		mode = pause_origin
	else:
		fight.start()
		pending_attack_cue=false
		hit_flash = 0
		opponent_flash = 0
		block_flash = 0
		punch_anim = 0
		mode = "fight"
	_release_stick()
	keyboard_high = false
	_reset_controller()
	guard_sources.clear()
	touches.clear()
	_update_buttons()

func toggle_pause() -> void:
	if mode in ["fight","entrance"]:
		pause_origin = mode
		mode = "paused"
	elif mode == "paused": mode = pause_origin
	else: return
	_release_stick()
	keyboard_high = false
	_reset_controller()
	guard_sources.clear()
	touches.clear()
	fight.set_guard(false)
	fight.release_all()
	_update_buttons()

func _update_buttons() -> void:
	for button in actions: button.visible = mode == "fight"
	start_button.visible = mode in ["intro","paused","result"]
	pause_button.visible = mode in ["fight","entrance","paused"]
	if mode == "intro":
		start_button.position = Vector2(48, 837)
		start_button.text = "START"
	else:
		start_button.position = Vector2(48, 596)
		start_button.text = "RESUME" if mode == "paused" else "REMATCH  "

func _physics_process(_delta: float) -> void:
	if mode == "entrance":
		entrance.step()
		if not entrance.error.is_empty():
			push_error(entrance.error)
			mode = "intro"
			_update_buttons()
		elif entrance.done: _start_or_resume()
		return
	if mode == "fight":
		fight.aim_high = keyboard_high or stick_direction == "up" or controller_state.get("high",false)
		fight.step()

func _process(delta: float) -> void:
	clock += delta
	ringside.advance(delta)
	_flush_impacts()
	_flush_attack_cue()
	feedback_time = maxf(0.0, feedback_time - delta)
	hit_flash = maxf(0.0, hit_flash - delta * 2.4)
	opponent_flash = maxf(0.0, opponent_flash - delta * 3.5)
	block_flash = maxf(0.0, block_flash - delta)
	punch_anim = maxf(0.0, punch_anim - delta * 4.5)
	if actions.size() == 3:
		actions[2].text = ""
		actions[2].modulate = Color.WHITE if fight.stars > 0 else Color(0.55,0.55,0.55)
	var control_alpha:float=1.0-fight.round_fade if fight.post_bell_started and fight.state!="between_rounds" else 1.0
	if not fight.round_scene_visible:control_alpha=0.0
	for button in actions:button.modulate.a=control_alpha
	pause_button.modulate.a=control_alpha
	queue_redraw()

func _on_combat_event(kind: String, detail: String) -> void:
	animation_timeline.event(kind, fight)
	if kind in ["hit", "counter", "hurt", "guard"]:
		pending_impacts.append({"kind":kind,"tick":fight.ticks,"high":punch_high,"ready_tick":fight.ticks+(1 if kind in ["hurt","guard"] else 0)})
		if pending_impacts.size()>8: pending_impacts.pop_front()
	if kind == "knockdown": ringside.cheer = 3.0
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
		"tell": pending_attack_cue=fight.opponent_action==21
		"evade", "guard": play_tone(740.0, 0.07, 0.08)
		"finish":
			mode = "result"
			_release_stick()
			keyboard_high = false
			_reset_controller()
			guard_sources.clear()
			touches.clear()
			_update_buttons()
			play_tone(660.0 if detail == "win" else 130.0, 0.4, 0.16)

func _flush_attack_cue() -> void:
	if not pending_attack_cue or mode!="fight":return
	if (fight.animation.m[0x90]&127)!=21:
		pending_attack_cue=false
		return
	var row: Dictionary=fight.animation.current("opponent")
	if int(row.get("visual_pose_id",-1))==12:
		# Authored sound follows the recovered visible windup, not state entry.
		pending_attack_cue=false
		play_tone(520.0,0.08,0.1)

func _flush_impacts() -> void:
	# Events occur before finish_tick commits displayed poses. Resolve their
	# positions afterwards so sparks never appear at the preceding glove pose.
	var waiting: Array=[]
	for event in pending_impacts:
		if fight.ticks<int(event.ready_tick):
			waiting.append(event)
			continue
		if fight.ticks-int(event.tick)>2: continue
		var role := "player" if event.kind in ["hit","counter"] else "opponent"
		var row: Dictionary = animation_timeline.current(fight,role)
		if row.get("box",[]).is_empty(): continue
		var at: Vector2
		if role == "player" and not row.get("tip",[]).is_empty():
			at=source_point(Vector2(row.tip[0],row.tip[1]))
		else:
			var defender: Dictionary = animation_timeline.current(fight,"player")
			if defender.get("box",[]).is_empty(): continue
			var b: Array=defender.box
			at=source_point(Vector2(float(b[0])+float(b[2])*0.5,float(b[1])+float(b[3])*0.25))
		if event.kind=="hurt":
			# Damage is already resolved; presentation waits for the strike pose.
			hit_flash=0.8
			play_tone(55.0,0.15,0.4)
		ringside.impact(at,event.kind=="counter",event.kind=="hurt")
	pending_impacts=waiting

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
	panel(rect.grow(3), INK, 8)
	panel(rect, Color("384b50"), 6)
	if fraction > 0: panel(Rect2(rect.position, Vector2(rect.size.x * clampf(fraction, 0, 1), rect.size.y)), color, 6)

func _draw() -> void:
	if mode == "intro":
		title_view.draw(self,clock)
		return
	draw_rect(Rect2(0,0,540,960),INK)
	_draw_arena()
	_draw_opponent()
	_draw_referee()
	_draw_player()
	_draw_contact_glove()
	_draw_front_apron()
	ringside.effects(self)
	# Minimal status: two names, two bars, clock and compact resource icons.
	interface.card(self,Rect2(12,12,516,110))
	text("NICO",Vector2(68,32),12,CORAL)
	interface.meter(self,Rect2(52,38,410,31),float(fight.opponent_hp)/96,CORAL)
	text("TEO",Vector2(68,84),12,MINT)
	interface.meter(self,Rect2(52,89,280,25),float(fight.hp)/96,MINT)
	interface.icon(self,"left",Rect2(22,39,29,29))
	interface.icon(self,"right",Rect2(22,87,26,26),MINT)
	var seconds := int(fight.round_centis/100.0)
	if fight.animation.clock_visible:text("%d:%02d" % [int(seconds/60.0),seconds%60],Vector2(389,105),22,PAPER)
	text("R%d" % fight.round_number,Vector2(349,103),12,MUTED)
	if mode == "fight":
		interface.card(self,Rect2(18,646,504,62))
		interface.icon(self,"heart",Rect2(34,664,30,28))
		text(str(fight.hearts),Vector2(76,687),22,PAPER)
		draw_line(Vector2(126,657),Vector2(126,697),Color("486373"),2)
		text("SCORE",Vector2(151,667),10,MUTED)
		text("%06d" % fight.points,Vector2(151,691),20,PAPER)
		draw_line(Vector2(292,657),Vector2(292,697),Color("486373"),2)
		for i in 3:
			interface.icon(self,"special",Rect2(320+i*58,660,36,36),Color.WHITE if i<fight.stars else Color(0.36,0.43,0.48))
		for i in 3:
			draw_circle(Vector2(398+i*15,28),4,CORAL if i<fight.opponent_downs else Color("394554"))
		draw_joystick()
		if fight.state == "between_rounds": centered("ROUND OVER",182,24,PAPER)
	_draw_referee_speech()
	if hit_flash>0: draw_rect(Rect2(0,122,540,540),Color(1,0.22,0.15,hit_flash*0.14))
	if fight.post_bell_started and fight.round_fade>0:
		draw_rect(Rect2(0,0,540,960),Color(0,0,0,fight.round_fade))
		if fight.state=="between_rounds":
			centered("ROUND OVER",420,32,PAPER)
			centered("TAP A PUNCH TO CONTINUE",470,18,MINT)
	if not fight.round_scene_visible:draw_rect(Rect2(0,0,540,960),Color.BLACK)
	if mode == "intro": _draw_intro()
	elif mode == "paused" or mode == "result": _draw_overlay()

func _draw_arena() -> void:
	draw_texture_rect(interface.ring,Rect2(-40,-140,620,1194),false)
	# Small engine-driven confetti/cheer motion overlays the painted audience.
	if ringside.cheer>0:
		for i in 18:
			var phase := clock*8+i*1.7
			var at := Vector2(25+i*29,204-absf(sin(phase))*13)
			draw_line(at,at+Vector2(sin(phase)*3,-5),CORAL if i%2==0 else MINT,2,true)

# Uniform NES-to-portrait transform. All motion below comes from sampled data.
const SOURCE_SCALE := 2.6
func source_point(p: Vector2) -> Vector2:
	return Vector2(270, 256) + (p - Vector2(132, 89)) * SOURCE_SCALE

func _opponent_mat_anchor(full: Array, pose: int, height: float, original: Vector2) -> Vector2:
	# Authored portrait-ring projection. Source actor state/timing stays intact.
	# Blend back to the existing glove/contact registration at fighting depth.
	var source_floor := float(full[1])+float(full[3])
	var depth := smoothstep(0.0,1.0,clampf((188.0-source_floor)/40.0,0.0,1.0))
	var center := float(full[0])+float(full[2])*0.5
	var floor_y := 538.0+(source_floor-188.0)*1.2
	# The prone drawing rests on its torso; elevated boots are not its pivot.
	var contact := 0.65 if pose in [14,34] else 1.0
	var projected := Vector2(270.0+center-132.0,floor_y-height*contact)
	return original.lerp(projected,depth)

func _draw_opponent() -> void: _draw_measured_actor("opponent", fighter_texture)
func _draw_player() -> void: _draw_measured_actor("player", player_texture)

func _art_pose(row: Dictionary, _role: String) -> int:
	return int(row.get("art_frame", 24))

func _draw_measured_actor(role: String, texture: Texture2D) -> void:
	if role == "opponent": contact_glove_draw.clear()
	if texture == null: return
	var row: Dictionary = entrance.current(role) if _presentation_mode() == "entrance" else animation_timeline.current(fight, role)
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
	# Preserve source movement while registering the new cartoon anatomy.
	var target_height := float(full[3]) * SOURCE_SCALE
	if role == "opponent":
		# Authored visual registration, not recovered geometry or contact reach.
		var heights := {9:240.0,13:245.0,14:195.0,22:220.0,23:230.0,32:300.0,33:265.0,34:195.0,35:220.0,36:245.0,37:330.0}
		target_height = float(heights.get(pose, 280.0))
	var art_scale := target_height / region.size.y
	var art_width := region.size.x * art_scale
	# Offscreen bodies must be cropped, not shrunk. Extent is restored only
	# where a full observed source silhouette exactly matches the visible part.
	if row.has("crop_y"):
		region.position.y += region.size.y * float(row.crop_y[0])
		region.size.y *= float(row.crop_y[1])
	var flip: bool = bool(row.get("art_flip", false)) != bool(registration.get("flip_correction", false))
	# Select the pose from the displayed PPU/OAM composition. Particle islands
	# are separate so they cannot stretch the boxer when an impact appears.
	var anchor := source_point(Vector2(float(full[0])+float(full[2])/2,float(b[1])))
	if role == "opponent":
		# Standing poses follow the source head/top anchor; fallen poses use
		# a floor pivot. A foot pivot pulled the large cartoon head out of reach.
		if pose in [13,14,22,23,32,33,34,35,36]:
			anchor.y += float(full[3]) * SOURCE_SCALE - target_height
		# Prone artwork's boots are above the mat; its bottom is not a standing
		# foot pivot. Authored floor registration keeps the torso inside the ring.
		# Prone -> kneeling -> rising share one floor offset. Changing it per
		# pose caused a 40-pixel pop while the source ground anchor was fixed.
		var floor_pivots := {13:30.0,33:30.0,14:65.0,34:65.0,22:65.0,35:65.0,23:65.0,36:65.0}
		anchor.y += float(floor_pivots.get(pose, 0.0))
	if role == "opponent":
		anchor = _opponent_mat_anchor(full,pose,target_height,anchor)
		var depth := clampf((188.0-float(full[1])-float(full[3]))/40.0,0.0,1.0)
		if depth>0.0:
			var floor_y := 538.0+(float(full[1])+float(full[3])-188.0)*1.2
			draw_set_transform(Vector2(anchor.x,floor_y),0,Vector2(1,0.12))
			draw_circle(Vector2.ZERO,art_width*0.36,Color(0.04,0.10,0.12,0.22*depth))
			draw_set_transform(Vector2.ZERO)
	# Register the striking glove to the recovered reach marker. This is an
	# authored-art transform, never a change to the source collision outcome.
	if role == "player" and pose in [13,16,17,19,20,21,22] and not row.tip.is_empty():
		var tip: Array = registration.tip
		var local_tip := Vector2((float(tip[0])-float(r[2])*0.5)*(-1 if flip else 1),float(tip[1]))*art_scale
		anchor = source_point(Vector2(row.tip[0],row.tip[1]))-local_tip
	if role == "opponent" and pose == 9:
		contact_glove_draw={"anchor":anchor,"scale":art_scale,"width":art_width,"region":r,"texture":texture,"flip":flip}
	draw_set_transform(anchor, 0, Vector2(-1 if flip else 1, 1))
	# Authored coral tint; pulse onset/duration comes from source palette writes.
	var tint:=Color(1.0,0.65,0.65) if role=="opponent" and row.get("palette_pulse",false) else Color.WHITE
	isolated_sprite.draw(self,texture,registration,region,art_width,art_scale,tint)
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

func _presentation_mode() -> String:
	return pause_origin if mode=="paused" else mode

func _draw_referee() -> void:
	if _presentation_mode() not in ["entrance","fight","result"]:return
	var source: Dictionary=entrance.current("referee") if _presentation_mode()=="entrance" else fight.animation.current("referee")
	if source.is_empty():return
	var pose:=int(source.art)
	var row: Dictionary=referee_art[pose]
	var r: Array=row.region;var region:=Rect2(r[0],r[1],r[2],r[3])
	var b: Array=source.box
	# Source body position/timing; original cartoon silhouette and scale registration.
	var height:=130.0
	var anchor:=source_point(Vector2(float(source.get("draw_x",float(b[0])+float(b[2])/2.0)),float(b[1])+float(b[3])))
	var scale:=height/float(row.get("body_height",region.size.y))
	var flip:=pose<3
	var foot_offset:float=(float(row.get("foot_x",region.size.x/2))-region.size.x/2)*scale*(-1 if flip else 1)
	draw_set_transform(anchor-Vector2(foot_offset,region.size.y*scale),0,Vector2(-1 if flip else 1,1))
	if not recovered_textures.has(row.texture):recovered_textures[row.texture]=load(row.texture)
	var pose_texture:Texture2D=recovered_textures[row.texture]
	isolated_sprite.draw(self,pose_texture,row,region,region.size.x*scale,scale)
	draw_set_transform(Vector2.ZERO)

func _draw_referee_speech() -> void:
	if _presentation_mode() not in ["entrance","fight","result"]:return
	var row: Dictionary=entrance.current("referee") if _presentation_mode()=="entrance" else fight.animation.current("referee")
	if not row.get("speech_visible",false):return
	var b: Array=row.box
	var feet:=source_point(Vector2(float(b[0])+float(b[2])/2,float(b[1])+float(b[3])))
	var center:=Vector2(clampf(feet.x-30,87,453),feet.y-174)
	# Original vector speech cloud; timing/text are decoded source commands.
	for pass_index in 2:
		var extra:=4.0 if pass_index==0 else 0.0
		var color:=INK if pass_index==0 else PAPER
		draw_colored_polygon(PackedVector2Array([center+Vector2(16,22),center+Vector2(43,50),center+Vector2(41,18)]),color)
		for i in 7:
			var angle:=TAU*float(i)/7
			draw_circle(center+Vector2(cos(angle)*43,sin(angle)*12),23+extra,color)
		draw_circle(center,34+extra,color)
	var label:=str(row.get("speech",""))
	var size_px:=24 if label.length()>2 else 32
	var width:=font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,size_px).x
	text(label,center+Vector2(-width/2,10),size_px,INK)

func _draw_front_apron() -> void:
	# The source walk-away crosses the bottom of the fighting viewport.
	# Align the foreground to source y=240 (portrait y=648.6).
	# Earlier y=588 occlusion hid the first recovered get-up poses.
	var dest := Rect2(0,649,540,85)
	var ring_rect := Rect2(-40,-140,620,1194)
	var scale_uv: Vector2 = interface.ring.get_size()/ring_rect.size
	var region := Rect2((dest.position-ring_rect.position)*scale_uv,dest.size*scale_uv)
	draw_texture_rect_region(interface.ring,dest,region)

func _draw_contact_glove() -> void:
	if contact_glove_draw.is_empty(): return
	var d: Dictionary = contact_glove_draw
	var tex: Texture2D = d.texture
	var r: Array = d.region
	# Traced interior of jab v3 (authored art, not source collision geometry).
	# Only this hand overlays
	# Teo; drawing Nico's entire body on top would hide the small boxer.
	var outline := PackedVector2Array([Vector2(625,612),Vector2(716,630),Vector2(770,691),Vector2(791,778),Vector2(778,855),Vector2(740,905),Vector2(682,935),Vector2(600,940),Vector2(532,914),Vector2(498,873),Vector2(480,840),Vector2(454,812),Vector2(445,773),Vector2(472,719),Vector2(522,663),Vector2(580,629)])
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for p in outline:
		points.append((p-Vector2(r[0],r[1]))*float(d.scale)-Vector2(float(d.width)/2,0))
		uv.append(p/tex.get_size())
	draw_set_transform(d.anchor,0,Vector2(-1 if d.flip else 1,1))
	draw_polygon(points,PackedColorArray([Color.WHITE]),uv,tex)
	draw_set_transform(Vector2.ZERO)

func _draw_cue() -> void:
	var title := "READ THE GUARD"
	var subtitle := "Head shots score. Body shots need an opening."
	var color := MUTED
	match fight.state:
		"windup":
			title = str(fight.attack.name)
			subtitle = "SLIP EITHER WAY   /   DOWN TO BLOCK"
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
	var down: bool = fight.state in ["opponent_down", "player_down", "countout"]
	centered(title, 202, 26 if down else 18, PAPER if down else color)
	centered(subtitle, 226, 12, PAPER if down else color)

func _draw_intro() -> void:
	panel(Rect2(24,669,492,151),Color(0.035,0.07,0.11,0.9),20)
	centered("NICO 'RIVET' REYES",704,25,PAPER)
	centered("Stick to slip  /  Gloves to punch",738,16,MUTED)
	interface.icon(self,"left",Rect2(197,754,40,40))
	interface.icon(self,"right",Rect2(250,754,40,40))
	interface.icon(self,"special",Rect2(303,754,40,40))

func _draw_overlay() -> void:
	draw_rect(Rect2(0, 176, 540, 784), Color(0.025, 0.05, 0.08, 0.86))
	panel(Rect2(24, 316, 492, 371), Color("1b3040"), 18)
	var win: bool = fight.result == "win"
	centered("TAKE A BREATH" if mode == "paused" else ("YOU OWN THE RING" if win else "BACK TO THE GYM"), 356, 12, MINT)
	centered("PAUSED" if mode == "paused" else ("VICTORY!" if win else ("KNOCKED OUT" if fight.hp == 0 else "OUTPOINTED")), 412, 39, PAPER if mode == "paused" else (MINT if win else CORAL))
	if mode == "paused":
		centered("Your fight is waiting.", 467, 20)
		centered("J / K fists  /  W head  /  S guard  /  A / D slip", 506, 15, MUTED)
		centered("Space: special  /  Escape: pause  /  SFX: sound", 536, 15, MUTED)
	else:
		centered(("Nico takes a knee. A new contender rises." if fight.opponent_hp == 0 else "The judges award you the bout.") if win else "Time your slip just before the strike.", 455, 16, MUTED)
		centered("%d COUNTERS     %d CLEAN DEFENSES" % [fight.counters, fight.avoids], 500, 17)
		centered("%d:%02d elapsed   /   %d hits taken" % [int(fight.ticks / 3600.0), (int(fight.ticks / 60.0)) % 60, fight.received], 535, 15, MUTED)
		centered("%s   /   %d POINTS" % [fight.verdict, fight.points], 565, 14, MUTED)



func draw_joystick() -> void:
	interface.icon(self,"stick_base",Rect2(STICK_CENTER-Vector2(91,91),Vector2(182,182)))
	interface.icon(self,"stick_cap",Rect2(STICK_CENTER+stick*44-Vector2(30,30),Vector2(60,60)))
