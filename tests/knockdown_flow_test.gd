extends SceneTree
const Fight=preload("res://scripts/fight_model_vm.gd")
var failures:=0
func check(value: bool,label: String) -> void:
 if not value:failures+=1;push_error(label)
 else:print("PASS: ",label)
func _initialize() -> void:
 # Controlled low-health fixtures exercise actual contacts, not forced KO poses.
 for hand in ["left","right"]:
  var fight=Fight.new();fight.start(1)
  for knockdown in 3:
   for _tick in 90:
    if not (fight.animation.m[0x51]&128):break
    fight.step()
   fight.opponent_hp=1
   # A pending combo was the original live-adapter stall trigger.
   fight.animation.m[0x4a]=80;fight.animation.m[0x4b]=2;fight.animation.m[0x4c]=1
   check(fight.act("head",hand),"%s accepts punch before KD %d" % [hand,knockdown+1])
   fight.release(hand)
   var saw_down:=false;var completed:=false
   for tick in 1400:
    fight.step()
    if fight.state=="opponent_down":saw_down=true
    if saw_down and (fight.state=="ready" or not fight.active):completed=true;break
   check(saw_down and completed and fight.animation_failure.is_empty(),"%s KD %d leaves combo and finishes count" % [hand,knockdown+1])
   if not completed:
    print("KD diagnostic: ",fight.state," active ",fight.active," down ",saw_down," m0/5/36/50/51/90/91/BB/C0/C1 ", [fight.animation.m[0],fight.animation.m[5],fight.animation.m[0x36],fight.animation.m[0x50],fight.animation.m[0x51],fight.animation.m[0x90],fight.animation.m[0x91],fight.animation.m[0xbb],fight.animation.m[0xc0],fight.animation.m[0xc1]])
    print("PC %04X return %04X cursor %d wait %d" % [fight.animation.m[0x54]+256*fight.animation.m[0x55]+fight.animation.m[0x53],fight.animation.m[0x56]+256*fight.animation.m[0x57],fight.animation.m[0x53],fight.animation.m[0x52]])
   if not completed:break
  check(fight.result=="win" and fight.verdict=="TKO","%s three knockdowns produce TKO" % hand)
 var player=Fight.new();player.start(1)
 for knockdown in 3:
  for _tick in 90:
   if not (player.animation.m[0x51]&128):break
   player.step()
  player.hp=1;player._begin_opponent("jab")
  var saw_player_down:=false;var completed:=false
  for tick in 1800:
   if player.state in ["player_down","countout"]:
    saw_player_down=true
    if player.state=="player_down" and tick%8==0:player.act("head","left");player.release("left")
   player.step()
   if saw_player_down and (player.state=="ready" or not player.active):completed=true;break
  check(completed and player.animation_failure.is_empty(),"Player jab knockdown %d completes" % [knockdown+1])
  if not completed:break
 check(player.result=="loss" and player.verdict=="TKO","Three player knockdowns produce TKO loss")
 var knockout=Fight.new();knockout.start(1)
 knockout.act("head","left");knockout.release("left")
 for tick in 1800:
  # Explicit instant-KO opening fixture; the contact and count run normally.
  if knockout.state!="opponent_down":knockout.animation.m[0xba]=255
  knockout.step()
  if not knockout.active:break
 check(knockout.result=="win" and knockout.verdict=="KO" and knockout.count==10,"Instant-KO opening counts to ten instead of taking TKO branch")
 var countout=Fight.new();countout.start(1);countout.hp=1;countout._begin_opponent("jab")
 for tick in 1800:
  countout.step()
  if not countout.active:break
 check(countout.result=="loss" and countout.verdict=="KO" and countout.count==10,"Player who does not get up loses by count of ten")
 print("Knockdown flow failures: ",failures)
 quit(1 if failures else 0)
