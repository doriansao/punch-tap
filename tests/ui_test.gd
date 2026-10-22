extends SceneTree
const Main = preload("res://scripts/main.gd")
var errors := 0
var passed := 0
func check(ok: bool, message: String) -> void:
 if ok: passed += 1
 else: errors += 1; printerr("FAIL: ",message)
func frames(game,n: int) -> void:
 for _i in range(n): game._physics_process(1.0/60.0)
func key(game,code:int,pressed:bool) -> void:
 var e=InputEventKey.new();e.keycode=code;e.pressed=pressed;game._input(e)
func _initialize() -> void: call_deferred("run_checks")
func run_checks() -> void:
 var game = Main.new()
 root.add_child(game)
 game.sound_on = false
 game.set_physics_process(false)
 check(game.mode == "intro" and game.start_button.visible,"Intro")
 game.start_button.pressed.emit()
 check(game.mode == "entrance", "Start runs recovered entrance")
 frames(game,887)
 check(game.fight.hp==96 and game.mode=="fight","Start recovered fight")
 key(game,KEY_K,true)
 check(game.fight.player_action=="right_body" and game.fight.opponent_hp==96,"Keyboard starts timed right punch without instant damage")
 frames(game,35)
 key(game,KEY_K,false)
 check(game.fight.hearts==19,"Body block spends visible heart")
 var touch=InputEventScreenTouch.new();touch.index=0;touch.position=Vector2(124,905);touch.pressed=true
 game._input(touch)
 check(game.fight.guard,"Joystick down holds guard")
 var drag=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(124,839)
 game._input(drag)
 frames(game,18) # Source guard releases through neutral, not held Up.
 drag.position=Vector2(124,775)
 game._input(drag)
 check(not game.fight.guard and game.stick_direction=="up","Joystick up aims high")
 frames(game,18)
 # Releasing guard must finish its recovered locked frames before punching.
 for _i in 90:
  if not (game.fight.animation.m[0x51]&128):break
  frames(game,1)
 var punch=InputEventScreenTouch.new();punch.index=1;punch.position=Vector2(440,880);punch.pressed=true
 game._input(punch)
 check(game.fight.player_action=="right_head" and game.punch_high,"Second finger right head punch")
 frames(game,12) # Stable-sample edge adds one tick before the punch starts.
 check(game.fight.opponent_hp==91,"Touch head contact applies recovered damage")
 punch.pressed=false;game._input(punch)
 check(game.stick_direction=="up","Punch release leaves aim held")
 touch.pressed=false;game._input(touch)
 check(game.stick==Vector2.ZERO,"Stick release neutral")
 frames(game,31)
 key(game,KEY_J,true)
 check(game.fight.player_action=="left_body","Neutral punch targets body")
 frames(game,36)
 check(not game.fight.act("body","left"),"Holding keyboard does not repeat after recovery")
 key(game,KEY_J,false)
 for _i in 90:
  if not (game.fight.animation.m[0x51]&128):break
  frames(game,1)
 game._move_stick(Vector2(195,839))
 check(game.fight.dodge=="right","Stick starts right slip")
 var hearts=game.fight.hearts
 game._move_stick(Vector2(195,839))
 check(game.fight.hearts==hearts,"Holding stick does not spend phantom stamina")
 game.toggle_pause()
 var before=game.fight.ticks;frames(game,20)
 check(game.mode=="paused" and game.fight.ticks==before and game.fight.held.is_empty(),"Pause freezes model and releases input")
 game.start_button.pressed.emit()
 game._notification(Control.NOTIFICATION_APPLICATION_FOCUS_OUT)
 check(game.mode=="paused" and not game.fight.guard,"Focus loss safe")
 game.start_button.pressed.emit()
 game.fight.finish("loss")
 check(game.mode=="result" and game.start_button.visible,"Result exposes rematch")
 game.start_button.pressed.emit()
 check(game.mode=="entrance", "Rematch plays entry")
 frames(game,887) # Rematch must complete the referee opening too.
 check(game.fight.hearts==20 and game.fight.stars==0 and game.fight.opponent_downs==0,"Rematch resets recovered resources")
 var saw_star=false
 var saw_knockdown=false
 for i in range(18000):
  var f=game.fight
  # Aim up for the punch, then release; permanently holding up invites guard AI.
  game.keyboard_high=false
  if f.stars>0: saw_star=true
  if f.state=="opponent_down":
   saw_knockdown=true
  if f.state=="between_rounds": game.perform_action("left");f.release("left")
  elif f.state=="player_down" and i%8==0:
   game.perform_action("left");f.release("left")
  elif f.state=="windup":
   if f.player_action.is_empty() and f.state_ticks>=6 and f.state_ticks<=12:game._move_stick(Vector2(50,839))
  elif i%25==0 and f.state not in ["taunt","opening","opponent_down","countout"]:
   game._release_stick()
   game.keyboard_high=true
   if f.stars>0: game.perform_action("special");f.release("special")
   else:
    var hand: String="left" if (i/25)%2==0 else "right"
    game.perform_action(hand);f.release(hand)
  frames(game,1)
  if not f.active: break
 check(saw_knockdown,"Natural input strategy reaches opponent knockdown")
 check(saw_star,"Natural input strategy earns a star")
 check(game.mode=="result" and game.fight.result in ["win","loss"],"Natural head/uppercut strategy completes bout without stalling")
 if game.fight.verdict=="DECISION":
  check(game.fight.result==("win" if game.fight.points>=5000 else "loss"),"Decision result agrees with score; completion does not imply victory")
 print("FINAL STATE: ",game.fight.state," actions ",game.fight.player_action," / ",game.fight.opponent_action," VM ",game.fight.animation.m[0x50]," / ",game.fight.animation.m[0x90]," hp ",game.fight.opponent_hp," count ",game.fight.count," phase ",game.fight.animation.m[5]," BB ",game.fight.animation.m[0xbb]," clock ",game.fight.round_centis)
 print("PLAYTHROUGH: ",game.fight.verdict," hp=",game.fight.hp," points=",game.fight.points," downs=",game.fight.opponent_downs," frames=",game.fight.ticks)
 game.queue_free()
 await process_frame
 print("UI TESTS: %d passed, %d failures"%[passed,errors])
 quit(0 if errors==0 else 1)
