extends "res://scripts/fight_model.gd"
## Live fight adapter. Animation commands own contact, defense, interruption,
## completion and knockdown progression; sampled tracks are comparison fixtures.
const AnimationMachine=preload("res://scripts/recovered/animation_machine.gd")
const NesRng=preload("res://scripts/recovered/nes_animation_rng.gd")
var animation=AnimationMachine.new()
var animation_failure:=""
var aim_high:=false
var queued_buttons:=0
func start(seed_value: int=1) -> void:
 animation.reset();animation_failure="";queued_buttons=0;aim_high=false
 super.start(seed_value)
func act(action: String,hand: String="left") -> bool:
 if state not in ["player_down","between_rounds"] and animation.m[0x51]&128:return false
 var accepted:=super.act(action,hand)
 if not accepted or state in ["player_down","between_rounds"]:return accepted
 if player_action.begins_with("left_"):animation.m[0xd5]=128;queued_buttons|=128
 elif player_action.begins_with("right_"):animation.m[0xd7]=128;queued_buttons|=64
 elif player_action=="special":animation.m[0xd9]=128;queued_buttons|=16
 else:
  animation.m[0xd3]=128
  queued_buttons|=2 if player_action=="dodge_left" else (1 if player_action=="dodge_right" else 4)
 if player_action.ends_with("_head"):queued_buttons|=8
 return accepted
func _raw_buttons() -> int:
 var value:=0
 if held.get("left",false):value|=128
 if held.get("right",false):value|=64
 if held.get("special",false):value|=16
 if guard or held.get("guard",false):value|=4
 if held.get("dodge_left",false):value|=2
 if held.get("dodge_right",false):value|=1
 if aim_high:value|=8
 return value
func step() -> void:
 if not active:return
 ticks+=1
 if state=="between_rounds":return
 var m: PackedInt32Array=animation.m
 m[0xd0]=_raw_buttons()|queued_buttons;m[0xd2]=m[0xd0]&15
 if not (m[0xd0]&7):m[0xd3]=0
 m[0xbc]=int(hearts>0);m[0x342]=stars;m[0x581]=speed_wait
 m[0x391]=hp;m[0x398]=opponent_hp
 var random_value: Vector2i=NesRng.advance((40+ticks)&255,m[0xd0],m[0x19])
 m[0x18]=random_value.x;m[0x19]=random_value.y
 animation.m=m
 var was_down:=state in ["player_down","opponent_down","countout"]
 if not was_down and animation.m[0x90]==1 and opponent_profile.is_empty():
  if not taunt_done and round_centis>=4000:
   taunt_done=true;_begin_opponent("taunt_long")
  elif taunt_done:_schedule()
 if not player_profile.is_empty():player_age+=1
 if not opponent_profile.is_empty():opponent_age+=1
 animation.tick();queued_buttons=0
 if not animation.error.is_empty():
  animation_failure=animation.error;active=false;push_error(animation_failure);return
 if was_down:
  _step_knockdown();return
 # Sprite/contact VMs consume stars through their shared command state.
 if player_action=="special" and player_age==1:stars=maxi(0,stars-1)
 var pstate: int=animation.m[0x50]&127
 var ostate: int=animation.m[0x90]&127
 if pstate in [1,2] and not player_action.is_empty():_clear_player()
 hit_stun=1 if pstate in [8,16,17] else 0
 if ostate==1:
  var was_taunt:=opponent_action==25
  _clear_opponent();state="ready"
  if was_taunt:first_jab_pending=true;scheduler_delay=1
 elif ostate in [21,22,25]:
  if ostate==25:state="opening" if animation.m[0xba]!=0 else "taunt"
  else:
   state="windup" if opponent_age<int(attack.windup) else "recovery"
   state_ticks=maxi(0,int(attack.windup)-opponent_age)
 else:state="reaction"
 # The original collision handler resolves an incoming contact first.
 if animation.m[0x98]&128:resolve_strike()
 elif animation.m[0x58]&128 and not player_profile.is_empty():_resolve_player_contact()
 animation.m[0x391]=hp;animation.m[0x398]=opponent_hp
 if state in ["player_down","opponent_down","countout"]:return
 if star_delay>0:
  star_delay-=1
  if star_delay==0:stars=mini(3,stars+1);points+=100;event.emit("star","STAR EARNED — SPECIAL AVAILABLE")
 var paused:=bool(animation.m[0x301]&1) or clock_pause>0
 if clock_pause>0:clock_pause-=1
 if not paused:round_centis+=5
 if round_centis>=18000:
  if round_number<3:
   state="between_rounds";release_all();_clear_player();_clear_opponent();event.emit("round","BELL — TAP A PUNCH TO CONTINUE")
  else:verdict="DECISION";finish("win" if points>=5000 else "loss")
func _begin_opponent(name: String) -> void:
 super._begin_opponent(name)
 animation.m[0x90]=opponent_action|128
func _opponent_frame() -> Dictionary:
 return {"defense":[animation.m[0xb6],animation.m[0xb7],animation.m[0xb8],animation.m[0xb9]],"ko":animation.m[0xba],"clock_pause":bool(animation.m[0x301]&1)}
func _player_defense(side: int) -> int:return animation.m[0x76+side]
func _resolve_player_contact() -> void:
 var target: int=animation.m[0x74]&3
 var force: int=animation.m[0x75]
 var defense: int=animation.m[0xb6+target]
 var special:=player_action=="special"
 player_profile=player_profile.duplicate(true);player_profile.target=target;player_profile.force=force
 if force>defense:
  animation.m[0x58]=3;animation.m[0x90]=(2 if special else 13+target)|128
 elif defense==8:
  animation.m[0x58]=1;animation.m[0x90]=(5+target)|128
 else:animation.m[0x58]=2
 super._resolve_player_contact()
 if force>defense or defense==8:
  animation.m[0x51]=129;animation.m[0x91]=129
  for address in [0x74,0x75,0x76,0x77,0xb4,0xb5,0xb6,0xb7,0xb8,0xb9]:animation.m[address]=0
func resolve_strike() -> void:
 var side: int=animation.m[0xb4]&1
 var protection:=_player_defense(side)
 animation.m[0x98]=4 if protection==255 else (2 if protection>=128 else (1 if protection==8 else 3))
 if protection<128:
  animation.m[0x50]=136 if protection==8 else (144+side)
  animation.m[0x51]=129;animation.m[0x91]=129
 super.resolve_strike()
 animation.m[0xb4]=0;animation.m[0xb5]=0
func _begin_knockdown(opponent: bool,instant_ko: bool) -> void:
 super._begin_knockdown(opponent,instant_ko)
 animation.begin_knockdown(opponent,getup_count,recovered_hp)
 if not opponent:
  animation.m[0x3c1]=2+12*mini(player_total_downs-1,2)
  animation.m[0x3c4]=getup_decay;animation.m[0x5d2]=getup_decay
  if state=="countout":animation.m[0xc0]=0
func _getup_press() -> bool:
 if animation.m[0xcf]==0 or (animation.m[0x3c3]&127)==0:return false
 animation.m[0xd5]=128
 return true
func _step_knockdown() -> void:
 down_age+=1
 count=clampi(animation.m[0xc1]-153,0,10)
 hp=animation.m[0x391];opponent_hp=animation.m[0x398]
 getup_needed=animation.m[0x3c3]&127
 if state=="player_down" and animation.m[0x36]==2 and stand_at<0:
  stand_at=down_age;recovered_hp=animation.m[0x397];recovered_hearts=animation.m[0x322];event.emit("getup","ON YOUR FEET!")
 if animation.m[0xbb]==255:
  if verdict.is_empty():verdict="KO"
  finish("win" if state=="opponent_down" else "loss")
 elif animation.m[5]==0:
  var player_recovered:=state=="player_down"
  state="ready";_clear_player();_clear_opponent();speed_wait=24;scheduler_delay=64;scheduler_pc=1
  if player_recovered:hearts=recovered_hearts
  event.emit("getup","BACK IN THE FIGHT")
func _next_round() -> void:
 super._next_round()
 animation.reset();animation.m[0x391]=hp;animation.m[0x398]=opponent_hp
