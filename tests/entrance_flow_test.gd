extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scripts/main.gd").new();root.add_child(game)
 game.sound_on=false;game.set_physics_process(false);game.set_process(false)
 game.start_button.pressed.emit()
 assert(game.mode=="entrance" and not game.start_button.visible,"Start must run an unskippable referee opening")
 for i in 5:game._physics_process(1.0/60)
 assert(not game.entrance.current("referee").is_empty(),"Referee must appear at beginning")
 game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
 assert(game.mode=="paused" and game.pause_origin=="entrance")
 var tick: int=game.entrance.ticks
 for i in 60:game._physics_process(1.0/60)
 assert(game.entrance.ticks==tick,"Background must not consume referee opening")
 game.start_button.pressed.emit()
 assert(game.mode=="entrance","Resume must return to entrance, not reset into combat")
 var speech_ticks: Array=[]
 while game.mode=="entrance":
  var row: Dictionary=game.entrance.current("referee")
  if row.get("speech","")=="FIGHT!":speech_ticks.append(game.entrance.ticks)
  # Repeated start activation cannot bypass the call.
  game.start_button.pressed.emit()
  assert(game.mode=="entrance")
  game._physics_process(1.0/60)
 assert(game.mode=="fight" and game.entrance.ticks==887)
 assert(speech_ticks.size()==23 and speech_ticks[0]==779 and speech_ticks[-1]==801,"Preserve recovered displayed FIGHT duration")
 print("ENTRANCE UI FLOW: visible referee, background pause/resume, no bypass; FIGHT ticks 779..801, combat at 887")
 game.queue_free();await process_frame;quit()
