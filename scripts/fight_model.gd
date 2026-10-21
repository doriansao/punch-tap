extends RefCounted
## Recovered first-opponent mechanics. Semantic schedules and measured animation
## tracks are in assets/data/recovered_rules.json. See RECOVERY_UPDATE.txt for
## fidelity boundaries (this is not a cycle-exact 6502/PPU emulator).
signal event(kind: String, detail: String)
const Opponent = preload("res://scripts/opponent_identity.gd")
const RULES_PATH = "res://assets/data/recovered_rules.json"
var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
var rng := RandomNumberGenerator.new()
var active := false
var result := ""
var verdict := ""
var hp := 96
var opponent_hp := 96
var hearts := 20
var stars := 0
var star_hits_left := 20
var star_delay := 0
var ticks := 0
var round_number := 1
var round_centis := 0
var points := 0
var state := "ready"
var state_ticks := 0
var attack: Dictionary = {"name": "JAB", "safe": "either", "windup": 44, "heavy": false}
var guard := false
var dodge := ""
var dodge_ticks := 0
var punch_cooldown := 0
var hit_stun := 0
var hits := 0
var counters := 0
var avoids := 0
var received := 0
var player_action := ""
var player_age := -1
var player_profile: Dictionary = {}
var player_pose := "ready"
var opponent_profile: Dictionary = {}
var opponent_age := -1
var opponent_action := 1
var speed_wait := 24
var scheduler_pc := 0
var scheduler_delay := 1
var schedule_name := "normal"
var taunt_done := false
var first_jab_pending := false
var clock_pause := 0
var reaction_ticks := 0
var opponent_downs := 0
var player_downs := 0
var player_total_downs := 0
var down_age := 0
var count := 0
var getup_count := 0
var getup_needed := 7
var getup_decay := 17
var stand_at := -1
var recovered_hp := 0
var recovered_hearts := 0
var held: Dictionary = {}

# Compatibility accessors for the HUD; no regenerating stamina/charge exists.
var stamina: float:
 get: return float(hearts)
var special_charge: int:
 get: return stars

func start(seed_value: int = 1) -> void:
 rng.seed = seed_value
 active = true
 result = ""
 verdict = ""
 hp = 96
 opponent_hp = 96
 hearts = 20
 stars = 0
 star_hits_left = 20
 star_delay = 0
 ticks = 0
 round_number = 1
 round_centis = 0
 points = 0
 state = "ready"
 hits = 0
 counters = 0
 avoids = 0
 received = 0
 opponent_downs = 0
 player_downs = 0
 player_total_downs = 0
 taunt_done = false
 first_jab_pending = false
 clock_pause = 0
 reaction_ticks = 0
 speed_wait = 24
 scheduler_pc = 0
 scheduler_delay = 1
 schedule_name = "normal"
 guard = false
 held.clear()
 _clear_player()
 _clear_opponent()
 event.emit("start", "HEAD SHOTS SCORE. WATCH FOR THE OPENING.")

func _clear_player() -> void:
 player_action = ""
 player_profile = {}
 player_age = -1
 player_pose = "ready"
 punch_cooldown = 0
 hit_stun = 0
 dodge = ""
 dodge_ticks = 0

func _clear_opponent() -> void:
 opponent_profile = {}
 opponent_age = -1
 opponent_action = 1
 state_ticks = 0

func release(action: String) -> void:
 held.erase(action)

func release_all() -> void:
 held.clear()
 guard = false

func set_guard(value: bool) -> void:
 if value and not guard:
  guard = true
  act("guard")
 elif not value:
  guard = false
  release("guard")

func act(action: String, hand: String = "left") -> bool:
 if not active: return false
 var key := hand if action == "head" or action == "body" else action
 if held.get(key, false): return false
 held[key] = true
 if state == "between_rounds":
  _next_round()
  return true
 if state == "player_down":
  if action in ["head", "body", "left", "right"]:
   return _getup_press()
  return false
 if state == "opponent_down" or state == "countout": return false
 if not player_profile.is_empty() or hit_stun > 0: return false
 if hearts == 0 and action in ["head", "body", "special"]:
  event.emit("tired", "NO HEARTS — DODGE TO RECOVER")
  return false
 if action == "special" and stars == 0:
  event.emit("tired", "EARN A STAR FIRST")
  return false
 var name := action
 if action in ["head", "body"]: name = hand + "_" + action
 if action == "guard": name = "down"
 if not rules.player.has(name): return false
 player_action = name
 player_profile = rules.player[name]
 player_age = -1
 player_pose = name
 punch_cooldown = int(player_profile.duration) + 1
 if name.begins_with("dodge"):
  dodge = name.trim_prefix("dodge_")
  dodge_ticks = int(player_profile.duration)
  event.emit("dodge", dodge)
 elif name != "down":
  event.emit("punch", hand + "_" + action)
 return true

func step() -> void:
 if not active: return
 ticks += 1
 if state == "between_rounds": return
 if state in ["player_down", "opponent_down", "countout"]:
  _step_knockdown()
  return
 if star_delay > 0:
  star_delay -= 1
  if star_delay == 0:
   stars = mini(3, stars + 1)
   points += 100
   event.emit("star", "STAR EARNED — SPECIAL AVAILABLE")
 if hit_stun > 0: hit_stun -= 1
 _advance_player()
 if reaction_ticks > 0:
  reaction_ticks -= 1
  state = "reaction"
  if reaction_ticks == 0:
   state = "ready"
   _clear_opponent()
 elif not opponent_profile.is_empty():
  _advance_opponent()
 else:
  state = "ready"
  if not taunt_done and round_centis >= 4000:
   taunt_done = true
   _begin_opponent("taunt_short" if rng.randi_range(0,15) < 8 else "taunt_long")
  elif taunt_done:
   _schedule()
 if not active or state in ["player_down", "opponent_down", "countout"]: return
 if not player_profile.is_empty() and player_age == int(player_profile.contact_at):
  _resolve_player_contact()
 if state in ["player_down", "opponent_down", "countout"]: return
 var paused := clock_pause > 0
 if clock_pause > 0: clock_pause -= 1
 if not opponent_profile.is_empty() and opponent_action == 25:
  paused = paused or bool(_opponent_frame().clock_pause)
 if not paused: round_centis += 5
 if round_centis >= 18000:
  # Inter-round presentation is adapted; health is preserved, no free heal.
  if round_number < 3:
   state = "between_rounds"
   release_all()
   _clear_player()
   _clear_opponent()
   event.emit("round", "BELL — TAP A PUNCH TO CONTINUE")
  else:
   # $AAC1 compares score digits with $05C8..$05CB: 0050xx (5000).
   verdict = "DECISION"
   finish("win" if points >= 5000 else "loss")

func _advance_player() -> void:
 if player_profile.is_empty(): return
 player_age += 1
 if player_action == "special" and player_age == 1: stars = maxi(0, stars - 1)
 var duration := int(player_profile.duration)
 if player_action == "down" and guard and player_age >= duration - 1:
  player_age = duration - 1
 punch_cooldown = maxi(0, duration + 1 - player_age)
 if not dodge.is_empty(): dodge_ticks = maxi(0, duration - player_age)
 if player_age > duration:
  _clear_player()

func _begin_opponent(name: String) -> void:
 opponent_profile = rules.opponent[name]
 opponent_age = -1
 opponent_action = int(opponent_profile.state)
 var contact_frame := int(opponent_profile.contact_at)
 if opponent_action == 21: contact_frame -= 24 - speed_wait
 attack = {"name": "JAB" if opponent_action == 21 else "BODY CROSS", "safe": "either", "windup": contact_frame, "heavy": false}
 state = "taunt" if opponent_action == 25 else "windup"
 event.emit("tell", Opponent.SHORT_NAME + " STEPS BACK — WAIT FOR HIS RETURN" if opponent_action == 25 else str(attack.name))

func _track_age() -> int:
 # The jab's $0581 wait is reduced after hits and reset after counters/script
 # changes. Only the wait interval changes; the remaining animation is retained.
 if opponent_action == 21 and opponent_age >= 19 + speed_wait:
  return opponent_age + 24 - speed_wait
 return maxi(0, opponent_age)

func _opponent_frame() -> Dictionary:
 if opponent_profile.is_empty(): return {"defense": [0,0,8,8], "ko": 0, "clock_pause": false}
 return opponent_profile.track[mini(_track_age(), opponent_profile.track.size()-1)]

func _advance_opponent() -> void:
 opponent_age += 1
 var age := _track_age()
 state_ticks = maxi(0, int(attack.windup) - opponent_age)
 if opponent_action == 25:
  state = "opening" if int(_opponent_frame().ko) != 0 else "taunt"
 else:
  var contact_frame := int(attack.windup)
  state = "windup" if opponent_age < contact_frame else ("strike" if opponent_age == contact_frame else "recovery")
  if opponent_age == contact_frame: resolve_strike()
 if state in ["player_down", "opponent_down", "countout"]: return
 if age >= int(opponent_profile.duration):
  var was_taunt := opponent_action == 25
  _clear_opponent()
  state = "ready"
  if was_taunt:
   first_jab_pending = true
   scheduler_delay = 1

func _schedule() -> void:
 var desired := "tired" if hearts == 0 else ("fast" if round_centis >= 6000 else "normal")
 if desired != schedule_name:
  schedule_name = desired
  scheduler_pc = 0
  scheduler_delay = 1
  speed_wait = 24
 scheduler_delay -= 1
 if scheduler_delay > 0: return
 if first_jab_pending:
  first_jab_pending = false
  scheduler_pc = 0
  scheduler_delay = 1
  _begin_opponent("jab")
  return
 var script: Dictionary = rules.schedules[schedule_name]
 for _guard in range(32):
  var op: Dictionary = script[str(scheduler_pc)]
  scheduler_pc = int(op.next)
  match str(op.op):
   "enable": continue
   "branch":
    if int(op.threshold) == 15 or rng.randi_range(0,15) < int(op.threshold): scheduler_pc = int(op.target)
   "wait":
    scheduler_delay = int(op.frames)
    return
   "attack":
    scheduler_delay = int(op.delay)
    _begin_opponent("jab" if int(op.id) == 21 else "cross")
    return
 push_error("Recovered scheduler exceeded command budget")

func _player_defense(side: int) -> int:
 if player_profile.is_empty() or player_age < 0 or player_age >= int(player_profile.duration): return 0
 return int(player_profile.defense[player_age][side])

func resolve_strike() -> void:
 var side := 1 if opponent_action == 22 else 0
 var protection := _player_defense(side)
 if protection >= 128:
  avoids += 1
  if hearts == 0:
   hearts = 10 if round_number == 3 else 15
   event.emit("evade", "CLEAN SLIP — HEARTS RESTORED")
  else: event.emit("evade", "CLEAN SLIP!")
  return
 if protection == 8:
  hp = maxi(0, hp - (4 if hearts == 0 else 2))
  hearts = maxi(0, hearts - 1)
  avoids += 1
  _clear_player()
  hit_stun = 16
  event.emit("guard", "BLOCKED  −2")
 else:
  hp = maxi(0, hp - 11)
  hearts = maxi(0, hearts - 3)
  stars = maxi(0, stars - 1)
  received += 1
  speed_wait = maxi(16, speed_wait - 1)
  _clear_player()
  hit_stun = 41
  event.emit("hurt", "HIT  −11")
 if hp == 0: _begin_knockdown(false, false)

func _resolve_player_contact() -> void:
 var target := int(player_profile.target)
 var special := player_action == "special"
 var defense := int(_opponent_frame().defense[target])
 var force := int(player_profile.force)
 if force <= defense:
  if defense == 8:
   hearts = maxi(0, hearts - 1)
   event.emit("blocked", "BLOCKED — CHANGE YOUR TARGET")
  else:
   event.emit("miss", "OUT OF REACH")
  return
 var knockout_flag := int(_opponent_frame().ko)
 var damage := force - defense + (8 if special else 0)
 var was_attacking := opponent_action in [21,22]
 opponent_hp = 0 if knockout_flag != 0 else maxi(0, opponent_hp - damage)
 hits += 1
 points += 500 if special else 10
 if was_attacking: counters += 1
 event.emit("counter" if was_attacking or special else "hit", ("STAR UPPERCUT" if special else "CLEAN HIT") + "  −%d" % damage)
 if opponent_hp == 0:
  _begin_knockdown(true, knockout_flag == 255)
  return
 speed_wait = 24
 if special:
  star_hits_left = maxi(1, star_hits_left - 1)
  clock_pause = 31
 else:
  star_hits_left -= 1
  if star_hits_left == 0:
   star_hits_left = 8
   star_delay = 31
 reaction_ticks = maxi(1, int(player_profile.duration) - player_age)
 state = "reaction"
 opponent_action = 2 if special else (13 if target == 0 else 14)
 opponent_profile = {}
 opponent_age = -1

func _begin_knockdown(opponent: bool, instant_ko: bool) -> void:
 _clear_player()
 _clear_opponent()
 reaction_ticks = 0
 release_all()
 down_age = 0
 count = 0
 stand_at = -1
 if opponent:
  opponent_downs += 1
  points += 1000
  state = "opponent_down"
  getup_count = int(rules.opponent_getup_counts[rng.randi_range(0,7)])
  recovered_hp = 80 if opponent_downs == 1 else 48
  if opponent_downs == 1 and round_number == 1 and round_centis < 6000 and hp == 96:
   getup_count = 1
   recovered_hp = 96
  if opponent_downs == 2 and hp == 96:
   getup_count = 1
   recovered_hp = 96
  if opponent_downs >= 3 or instant_ko:
   getup_count = 0
   verdict = "TKO" if opponent_downs >= 3 else "KO"
  event.emit("knockdown", Opponent.SHORT_NAME + " IS DOWN — COUNTING")
 else:
  player_downs += 1
  player_total_downs += 1
  state = "player_down"
  stars = 0
  getup_needed = 7
  getup_decay = 17 if player_total_downs == 1 else 16
  if player_downs >= 3:
   state = "countout"
   verdict = "TKO"
  event.emit("knockdown", "YOU ARE DOWN — TAP LEFT / RIGHT TO RISE")

func _getup_press() -> bool:
 if down_age < 215 or stand_at >= 0 or count >= 10: return false
 getup_needed = maxi(0, getup_needed - 1)
 if getup_needed == 0:
  var table: Array = rules.player_getup_tables[mini(player_total_downs-1,1)]
  var entry := int(table[clampi(count,0,9)])
  recovered_hp = (entry & 15) * 8
  recovered_hearts = maxi(1, ((entry & 48) >> 4) * 3)
  stand_at = down_age
  event.emit("getup", "ON YOUR FEET!")
 else: event.emit("getup", "%d MORE TAPS" % getup_needed)
 return true

func _step_knockdown() -> void:
 down_age += 1
 if state == "opponent_down":
  count = clampi(1 + int((down_age - 273) / 39.0), 0, 10) if down_age >= 273 else 0
  if getup_count > 0:
   count = mini(count, getup_count)
   var counted_at := 273 + (getup_count - 1) * 39
   if down_age == counted_at + 179: opponent_hp = recovered_hp
   if down_age >= counted_at + 243:
    state = "ready"
    speed_wait = 24
    scheduler_delay = 64
    scheduler_pc = 1
    event.emit("getup", Opponent.SHORT_NAME + " BEATS THE COUNT")
  elif down_age >= 728:
   finish("win")
 elif state == "countout":
  count = clampi(1 + int((down_age - 218) / 35.0),0,10) if down_age >= 218 else 0
  if down_age >= 728: finish("loss")
 else:
  count = clampi(1 + int((down_age - 218) / 35.0),0,10) if down_age >= 218 else 0
  if stand_at >= 0:
   if down_age >= stand_at + 60: hp = recovered_hp; hearts = recovered_hearts
   if down_age >= stand_at + 165:
    state = "ready"
    scheduler_delay = 64
    scheduler_pc = 1
    speed_wait = 24
    event.emit("getup", "BACK IN THE FIGHT")
  elif down_age >= 215 and getup_needed < 5:
   getup_decay -= 1
   if getup_decay <= 0:
    getup_needed += 1
    getup_decay = 17 if player_total_downs == 1 else 16
  if down_age >= 956 and stand_at < 0:
   verdict = "KO"
   finish("loss")

func _next_round() -> void:
 round_number += 1
 round_centis = 0
 hearts = maxi(hearts, 20 if round_number == 2 else 15)
 stars = 0
 opponent_downs = 0
 player_downs = 0
 taunt_done = false
 first_jab_pending = false
 speed_wait = 24
 scheduler_pc = 0
 scheduler_delay = 1
 state = "ready"
 event.emit("round", "ROUND %d" % round_number)

func finish(outcome: String) -> void:
 active = false
 release_all()
 result = outcome
 event.emit("finish", outcome)
