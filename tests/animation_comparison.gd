extends SceneTree
const Main = preload("res://scripts/main.gd")
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(540,960)
	var game = Main.new()
	root.add_child(game)
	game.sound_on = false
	game.set_physics_process(false)
	game._start_or_resume()
	game.show_animation_measurements = true
	var base := "G:/Programming/punch-tap/research/evidence/comparison"
	DirAccess.make_dir_recursive_absolute(base)
	var index := {}
	for clip in game.animation_timeline.tracks:
		var track: Dictionary = game.animation_timeline.tracks[clip]
		DirAccess.make_dir_recursive_absolute(base + "/" + clip)
		game.animation_timeline.override_clip = clip
		var rows := []
		for age in track.frames.size():
			game.animation_timeline.override_age = age
			game.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(base + "/" + clip + "/%04d.png" % age)
			var row: Dictionary = track.frames[age].duplicate(true)
			for role in ["player", "opponent"]:
				var selected: Dictionary = game.animation_timeline.sample(clip,age,role)
				var pose: int = game._art_pose(selected,role)
				row[role].art_pose = pose
				row[role].art_match = "explicit recovered-pose mapping; original anatomy, not pixel-identical silhouette"
			rows.append(row)
		index[clip] = {"case":track.case,"start":track.start,"frames":rows}
		print("COMPARISON_CAPTURED ",clip," ",rows.size())
	var file := FileAccess.open(base + "/index.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(index))
	file.close()
	quit()
