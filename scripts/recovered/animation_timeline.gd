extends RefCounted
## Measured render tracks. No sine bob, tween, contact-window pose heuristic.
## Sample selection is separate from unfinished combat branch/RNG recovery.
var tracks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/animation_tracks.json"))
var reaction_tick := -10000
var hurt_tick := -10000
var reaction_hand := "left"
var override_clip := ""
var override_age := 0

func event(kind: String, fight) -> void:
	if kind == "start": reaction_tick = -10000; hurt_tick = -10000
	if kind in ["hit", "counter", "blocked"]:
		reaction_tick = fight.ticks
		reaction_hand = "right" if fight.player_action.begins_with("right") else "left"
	if kind in ["hurt", "guard"]: hurt_tick = fight.ticks

func sample(clip: String, age: int, role: String) -> Dictionary:
	var data: Dictionary = tracks[clip]
	var rows: Array = data.frames
	var index := clampi(age, 0, rows.size() - 1)
	var result: Dictionary = rows[index][role].duplicate(true)
	result.source_frame = int(rows[index].frame)
	result.source_case = data.case
	result.clip = clip
	result.age = index
	return result

func current(fight, role: String) -> Dictionary:
	if not override_clip.is_empty():return sample(override_clip,override_age,role)
	return fight.animation.current(role)
