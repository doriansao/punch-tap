extends SceneTree
const Timeline = preload("res://scripts/recovered/animation_timeline.gd")
var failures := 0
func _initialize() -> void:
	var timeline = Timeline.new()
	var samples := 0
	var origins := {"visual_audit":2295,"normal_knockdowns":2295,"player_getup_wide":4000,"idle_long":2295}
	for clip in timeline.tracks:
		var track: Dictionary = timeline.tracks[clip]
		var ram := FileAccess.get_file_as_bytes("res://research/evidence/animation/" + track.case + "/full/ram.bin")
		for age in track.frames.size():
			var offset: int = (int(track.start) + age - int(origins[track.case])) * 2048
			var p: Dictionary = timeline.sample(clip,age,"player")
			var o: Dictionary = timeline.sample(clip,age,"opponent")
			var key := "%04X:%02X:%04X" % [int(ram[offset+0xA3])+256*int(ram[offset+0xA4]),ram[offset+0xA5],int(ram[offset+0xA6])+256*int(ram[offset+0xA7])]
			if int(p.pose) != ram[offset+0x61] or int(p.scroll) != ram[offset+0x15] or int(p.contact) != ram[offset+0x58] or o.pose != key or int(o.anchor[0]) != ram[offset+0xB0] or int(o.anchor[1]) != ram[offset+0xB1]:
				failures += 1
				printerr("SOURCE_MISMATCH ",clip," age ",age)
			samples += 1
	print("ANIMATION_SOURCE_CHECK: ",samples," paired samples, ",failures," mismatches. This checks source fields, not art silhouette parity.")
	quit(1 if failures else 0)
