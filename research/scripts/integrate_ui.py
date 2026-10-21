from pathlib import Path
p=Path('scripts/main.gd');s=p.read_text(encoding='utf-8')
s=s.replace('res://assets/mara_sheet.png','res://assets/mara_recovered.png')
s=s.replace('button.button_down.connect(func(): perform_action(action))','button.button_down.connect(func(): perform_action(action))\n\t\tbutton.button_up.connect(func(): fight.release(action))')
s=s.replace('elif touches.has(event.index):\n\t\t\ttouches.erase(event.index)','elif touches.has(event.index):\n\t\t\tfight.release(touches[event.index])\n\t\t\ttouches.erase(event.index)')
s=s.replace('if event.pressed:\n\t\t\tmatch event.keycode:', '''if not event.pressed:
			match event.keycode:
				KEY_J: fight.release("left")
				KEY_K: fight.release("right")
				KEY_SPACE: fight.release("special")
				KEY_A, KEY_LEFT: fight.release("dodge_left")
				KEY_D, KEY_RIGHT: fight.release("dodge_right")
		if event.pressed:
			match event.keycode:''')
s=s.replace('\t_guard_source("stick", direction == "down")','\tif direction != stick_direction and stick_direction in ["left", "right"]:\n\t\tfight.release("dodge_" + stick_direction)\n\t_guard_source("stick", direction == "down")')
s=s.replace('func _release_stick() -> void:\n','func _release_stick() -> void:\n\tfight.release("dodge_left")\n\tfight.release("dodge_right")\n')
s=s.replace('\tfight.set_guard(false)\n\t_update_buttons()','\tfight.set_guard(false)\n\tfight.release_all()\n\t_update_buttons()')
s=s.replace('actions[2].text = "SPECIAL  READY" if fight.special_charge == 3 else "SPECIAL  %d/3" % fight.special_charge','actions[2].text = "SPECIAL  ★ %d" % fight.stars if fight.stars > 0 else "SPECIAL  ☆"')
s=s.replace('float(fight.opponent_hp) / 100','float(fight.opponent_hp) / 96').replace('float(fight.hp) / 100','float(fight.hp) / 96')
s=s.replace('var remaining := maxi(0, 180 - int(fight.ticks / 60.0))','var remaining := int(fight.round_centis / 100.0)')
s=s.replace('"R01  %d:%02d" % [int(remaining / 60.0), remaining % 60]','"R%d  %d:%02d" % [fight.round_number, int(remaining / 60.0), remaining % 60]')
s=s.replace('Watch the tell. Slip late. Hit the opening.','Aim high. Read the guard. Save your stars.')
s=s.replace('text("STAMINA",','text("HEARTS",').replace('fight.stamina / 100.0, MINT if fight.stamina > 25 else CORAL','float(fight.hearts) / 20.0, MINT if fight.hearts > 0 else CORAL').replace('int(fight.stamina)','fight.hearts')
s=s.replace('fighter_texture.get_width() / 3.0','fighter_texture.get_width() / 4.0').replace('frame % 3, int(frame / 3.0)','frame % 4, int(frame / 4.0)')
a=s.index('\tif fight.state == "windup" and mode != "intro":',s.index('func _draw_opponent'))
b=s.index('\tvar region_size',a)
s=s[:a]+'''	if fight.state in ["taunt", "opening"]: frame = 1
	elif fight.state == "windup" and mode != "intro":
		frame = 2
		offset.x = sin(clock * 17) * 2
	elif fight.state == "strike":
		frame = 3
		offset.y = 12
	elif fight.state == "reaction": frame = 5
	if opponent_flash > 0: frame = 5
	if fight.state == "opponent_down":
		frame = 7 if fight.opponent_hp > 0 else 6
	if fight.result == "win": frame = 6
'''+s[b:]
s=s.replace('if mode == "intro" or mode == "result": return','if mode == "intro" or mode == "result" or fight.state in ["player_down", "countout"]: return')
s=s.replace('if fight.guard: at =','if fight.player_action == "down": at =')
s=s.replace('if punch_anim > 0 and side == punch_side:\n\t\t\tat = at.lerp(Vector2(270 + side * 20, 425 if punch_high else 520), sin(punch_anim * PI))', '''if not fight.player_profile.is_empty() and fight.player_action in ["left_body", "right_body", "left_head", "right_head", "special"] and side == punch_side:
			var contact_time := maxf(1, float(fight.player_profile.contact_at))
			var age := float(fight.player_age)
			var extension := age / contact_time if age <= contact_time else 1.0 - (age - contact_time) / maxf(1, float(fight.player_profile.duration) - contact_time)
			at = at.lerp(Vector2(270 + side * 20, 425 if punch_high else 520), clampf(extension, 0, 1))''')
a=s.index('func _draw_cue()');b=s.index('func _draw_intro()',a)
s=s[:a]+'''func _draw_cue() -> void:
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
		"taunt": title = "WAIT FOR THE RETURN"; subtitle = "She is out of reach"
		"opening": title = "CHIN OPEN!"; subtitle = "Time a clean punch"; color = MINT
		"opponent_down":
			title = "%d" % fight.count if fight.count > 0 else "KNOCKDOWN!"
			subtitle = "MARA MUST BEAT THE COUNT"
		"player_down":
			title = "%d" % fight.count if fight.count > 0 else "YOU ARE DOWN"
			subtitle = "TAP LEFT / RIGHT TO GET UP"; color = CORAL
		"countout": title = "TKO"; subtitle = "Three knockdowns in the round"
		"between_rounds": title = "ROUND OVER"; subtitle = "TAP A PUNCH TO CONTINUE"
	centered(title, 202, 18, color)
	centered(subtitle, 226, 12, color)

'''+s[b:]
s=s.replace('A quick jab. A late cross. Never the same rhythm.','Keep your guard. Catch her on the way back.')
s=s.replace('01   Watch the cue. Slip as the bar fills.','01   Aim high. Watch her guard and footwork.')
s=s.replace('03   Left / right punch. 3 counters earn special.','03   Earn stars. One star powers an uppercut.')
s=s.replace('ORIGINAL FIGHTERS  /  ORIGINAL RULES  /  FIRST PLAYABLE','ORIGINAL FIGHTERS  /  ROOFTOP CIRCUIT  /  BOUT ONE')
s=s.replace('("KNOCKED OUT" if fight.hp == 0 else "OUTPOINTED")','("KNOCKED OUT" if fight.hp == 0 else "OUTPOINTED")')
s=s.replace('"The bell rings. You win on remaining health."','"The judges award you the bout."')
s=s.replace('"Try another round. Learn the rhythm."','"%s  •  %d POINTS" % [fight.verdict, fight.points]')
p.write_text(s,encoding='utf-8')

