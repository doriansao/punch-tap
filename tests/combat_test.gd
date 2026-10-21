extends SceneTree
const Fight = preload("res://scripts/fight_model.gd")
var failures := 0
var passed := 0
func check(ok: bool, description: String) -> void:
 if not ok:
  failures += 1
  printerr("FAIL: ", description)
 else: passed += 1
func frames(f, n: int) -> void:
 for _i in range(n): f.step()
func _initialize() -> void:
 var f = Fight.new()
 f.start()
 check(f.hp == 96 and f.opponent_hp == 96 and f.hearts == 20 and f.stars == 0, "ROM starting resources")
 check(f.act("head", "left"), "Head punch accepted")
 frames(f,10)
 check(f.opponent_hp == 96, "No damage before contact")
 f.step()
 check(f.opponent_hp == 91 and f.hearts == 20, "Head contact deals five; successful punches do not spend visible hearts")
 check(not f.act("head", "left"), "Held punch cannot repeat")
 frames(f,40)
 check(not f.act("head", "left"), "Held punch stays latched after recovery")
 f.release("left")
 check(f.act("head", "left"), "Release allows a new press")
 f.start()
 f.act("body", "left")
 frames(f,12)
 check(f.opponent_hp == 96 and f.hearts == 19, "Blocked body contact costs one heart")
 f.start()
 f.act("dodge_left")
 frames(f,6)
 f.opponent_action = 21
 f.resolve_strike()
 check(f.hp == 85, "Dodge startup is vulnerable")
 for direction in ["left", "right"]:
  f.start()
  f.act("dodge_"+direction)
  frames(f,7)
  f.opponent_action = 21
  f.resolve_strike()
  check(f.hp == 96 and f.avoids == 1, "Both dodge directions avoid tested jab")
 f.start()
 f.set_guard(true)
 frames(f,80)
 check(f.player_action == "down", "Held guard stays up past minimum duration")
 f.opponent_action = 21
 f.resolve_strike()
 check(f.hp == 94 and f.hearts == 19, "Block takes two HP and one heart")
 f.start()
 f.hearts = 0
 check(not f.act("head"), "Exhaustion disables punches")
 f.act("dodge_left")
 frames(f,7)
 f.opponent_action = 21
 f.resolve_strike()
 check(f.hp == 96 and f.hearts == 15, "Exhausted dodge restores fifteen hearts")
 f.start()
 check(not f.act("special"), "Zero-star uppercut rejected")
 f.release("special")
 f.stars = 1
 check(f.act("special"), "One-star uppercut accepted")
 frames(f,2)
 check(f.stars == 0, "Uppercut consumes one star")
 frames(f,41)
 check(f.opponent_hp == 96, "Uppercut still winding up before age 43")
 f.step()
 check(f.opponent_hp == 73, "Idle target uppercut force15 + bonus8")
 f.start()
 f.stars = 1
 f.act("special")
 frames(f,43)
 f._begin_opponent("jab")
 f.opponent_age = 14
 f.step()
 check(f.opponent_hp == 79, "Uppercut vs jab defense6 deals17 as recorded")
 f.start()
 f.star_hits_left = 1
 f.act("head")
 frames(f,11)
 check(f.star_hits_left == 8 and f.stars == 0, "Qualifying hit resets star counter but star display is delayed")
 frames(f,31)
 check(f.stars == 1, "Observed delayed star award")
 f.stars = 3
 f.star_delay = 1
 f.step()
 check(f.stars == 3, "Three-star cap")
 f.start()
 f.round_centis = 7000
 f.taunt_done = true
 f.schedule_name = 'fast'
 f.scheduler_delay = 1000
 f.opponent_hp = 5
 f.act("head")
 frames(f,11)
 check(f.state == "opponent_down" and f.active and f.opponent_downs == 1, "Zero HP enters knockdown, not immediate victory")
 f.getup_count = 6
 frames(f,273)
 check(f.count == 1, "Referee begins first count at captured tick")
 frames(f,374)
 check(f.opponent_hp == 80 and f.state == "opponent_down", "Count-six opponent restores80 HP after647 ticks")
 frames(f,64)
 check(f.state == "ready", "Fight resumes after711 ticks")
 f.start()
 f._begin_opponent("taunt_long")
 f.opponent_age = 145
 f.player_profile = f.rules.player.left_head
 f.player_age = 10
 f.player_action = "left_head"
 f._resolve_player_contact()
 check(f.opponent_hp == 0 and f.getup_count == 0 and f.verdict == "KO", "Flag255 opening forces a countout regardless of HP")
 frames(f,728)
 check(f.result == "win", "Instant-KO branch completes the count")
 f.start()
 f.opponent_downs = 2
 f.opponent_hp = 0
 f._begin_knockdown(true,false)
 check(f.verdict == "TKO" and f.getup_count == 0, "Three knockdowns in one round force TKO")
 frames(f,728)
 check(f.result == "win", "TKO reaches result")
 f.start()
 f.hp = 11
 f.resolve_strike()
 check(f.state == "player_down" and f.active, "Player gets a recovery chance")
 frames(f,215)
 for _tap in range(20):
  f.act("body", "left")
  f.release("left")
  if f.stand_at >= 0: break
  frames(f,8)
 check(f.stand_at >= 0, "Separate punch presses beat the getup counter")
 var expected_hp: int = f.recovered_hp
 frames(f,165)
 check(f.state == "ready" and f.hp == expected_hp and f.hearts > 0, "Successful player getup restores count-dependent resources")
 f.start()
 f.hp = 11
 f.resolve_strike()
 frames(f,1000)
 check(f.result == "loss", "No taps leads to countout")
 f.start()
 var cases = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/player_actions.json"))
 var compared := 0
 for name in cases:
  if name == "hold_left": continue
  var trace: Dictionary = cases[name]
  f.start()
  for i in range(trace.state.size()):
   if i == int(trace.accepted_sample):
    if name.begins_with("dodge"): f.act(name)
    elif name == "down": f.set_guard(true)
    else: f.act("head" if name.ends_with("head") else "body", "left" if name.begins_with("left") else "right")
   if i == int(trace.accepted_sample) + 3 and name == "down": f.set_guard(false)
   f.step()
   var actual := 1
   if not f.player_profile.is_empty():
    actual = 129 if f.player_age == int(f.player_profile.duration) else int(f.player_profile.state)
   if actual != int(trace.state[i]):
    check(false,"Integrated player action trace %s frame %d (%d != %d)" % [name,i,actual,int(trace.state[i])])
    break
   compared += 1
 check(compared == 2142, "Integrated engine matches all2142 action-state samples")
 # Independent outcome checks from the emulator's idle attack captures.
 f.start()
 f._begin_opponent("jab")
 frames(f,44)
 check(f.hp==96,"ROM jab stays in anticipation through age43")
 f.step()
 check(f.hp==85 and f.hearts==17,"ROM jab contact at age44: 11HP and3 hearts")
 f.start()
 f._begin_opponent("cross")
 frames(f,58)
 check(f.hp==96,"ROM cross anticipation through age57")
 f.step()
 check(f.hp==85,"ROM cross contact at age58")
 f.start()
 f.act("head")
 frames(f,11)
 check(f.points==10,"Normal hit scores10 from decimal score RAM")
 f.start()
 f.round_number=3
 f.round_centis=17995
 f.taunt_done=true
 f.schedule_name="fast"
 f.scheduler_delay=100
 f.points=4990
 f.step()
 check(f.result=="loss","Recovered decision threshold rejects4990")
 f.start()
 f.round_number=3
 f.round_centis=17995
 f.taunt_done=true
 f.schedule_name="fast"
 f.scheduler_delay=100
 f.points=5000
 f.step()
 check(f.result=="win" and f.verdict=="DECISION","Recovered score comparison accepts5000")
 print("COMBAT TESTS: %d passed, %d failures; %d integrated ROM samples" % [passed,failures,compared])
 quit(0 if failures==0 else 1)

