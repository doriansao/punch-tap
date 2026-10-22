extends "res://scripts/fight_model.gd"
## Live fight adapter. Animation commands own contact, defense, interruption,
## completion and knockdown progression; sampled tracks are comparison fixtures.
const AnimationMachine=preload("res://scripts/recovered/animation_machine.gd")
const ControllerPoll=preload("res://scripts/recovered/controller_poll.gd")
const NesRng=preload("res://scripts/recovered/nes_animation_rng.gd")
const KnockdownEntry=preload("res://scripts/recovered/knockdown_entry.gd")
const ContactVM=preload("res://scripts/recovered/contact_vm.gd")
var contact_vm=ContactVM.new()
var animation=AnimationMachine.new()
var animation_failure:=""
var round_scene_visible:=true
var round_entry_wait:=-1
var post_bell_started:=false
var post_bell_wait:=-1
var round_fade:=0.0
var pending_palette_fade:=-1
var aim_high:=false
var queued_buttons:=0
var queued_button_frames:=0
func start(seed_value: int=1) -> void:
 post_bell_started=false;post_bell_wait=-1;round_fade=0.0;pending_palette_fade=-1;round_entry_wait=-1
 round_scene_visible=true
 animation.reset();animation_failure="";queued_buttons=0;queued_button_frames=0;aim_high=false
 super.start(seed_value)
 animation.fight_control_enabled=true
 for address in animation.geometry.fight_initial:animation.m[int(address)]=int(animation.geometry.fight_initial[address])
 animation.prime_display()
 round_centis=_source_clock()
func act(action: String,hand: String="left") -> bool:
 if post_bell_started and state!="between_rounds":return false
 if state not in ["player_down","between_rounds"] and animation.m[0x51]&128:return false
 var continuing_round:=state=="between_rounds"
 var accepted:=super.act(action,hand)
 if continuing_round:return accepted
 if not accepted or state in ["player_down","between_rounds"]:return accepted
 if player_action.begins_with("left_"):queued_buttons|=128
 elif player_action.begins_with("right_"):queued_buttons|=64
 elif player_action=="special":queued_buttons|=16
 else:
  queued_buttons|=2 if player_action=="dodge_left" else (1 if player_action=="dodge_right" else 4)
 queued_button_frames=2 # Two stable samples let the recovered poll create an edge.
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
 if round_number>1 and round_entry_wait>=0:round_scene_visible=animation.m[0x1b]==1
 if animation.m[0]==48:round_entry_wait=3
 # $A774 follows the capture checkpoint; apply its writes before next tick.
 if pending_palette_fade>=0:
  for address in range(0x480,0x4a0):
   var value:int=animation.m[address]
   if value<128 and value>=pending_palette_fade:animation.m[address]=value-16 if value>=16 else 143
  pending_palette_fade=-1
 var m: PackedInt32Array=animation.m
 var previous_buttons:=m[0xd0] # Source RNG runs before the new controller poll.
 m=ControllerPoll.step(m,_raw_buttons()|queued_buttons)
 # $BC is a source-controlled fatigue/recovery flag, not hearts > 0.
 # Player knockdown sets it even when the displayed heart count is zero.
 m[0x342]=stars
 m[0x391]=hp;m[0x392]=hp;m[0x398]=opponent_hp;m[0x399]=opponent_hp
 m[0x323]=hearts/10;m[0x324]=hearts%10
 m[6]=round_number
 var random_value: Vector2i=NesRng.advance((m[0x1e]+1)&255,previous_buttons,m[0x19])
 m[0x18]=random_value.x;m[0x19]=random_value.y
 animation.m=m
 var was_down:=state in ["player_down","opponent_down","countout"]
 if not player_profile.is_empty():player_age+=1
 if opponent_action in [21,22,25]:opponent_age+=1
 animation.tick(true)
 if queued_button_frames>0:
  queued_button_frames-=1
  if queued_button_frames==0:queued_buttons=0
 if not animation.error.is_empty():
  animation_failure=animation.error;active=false;push_error(animation_failure);return
 _sync_resources()
 speed_wait=animation.m[0x581]
 if was_down:
  animation.finish_tick()
  _step_knockdown();return
 var pstate: int=animation.m[0x50]&127
 var ostate: int=animation.m[0x90]&127
 if pstate in [1,2] and not player_action.is_empty():_clear_player()
 hit_stun=1 if pstate in [8,16,17] else 0
 if ostate==1:
  var was_taunt:=opponent_action==25
  _clear_opponent();state="ready"
  if was_taunt:first_jab_pending=true;scheduler_delay=1
 elif ostate in [21,22,25]:
  if opponent_action!=ostate:
   opponent_action=ostate;opponent_age=0
   attack={"name":"JAB" if ostate==21 else "BODY CROSS","safe":"either","windup":20+animation.m[0x581] if ostate==21 else 58,"heavy":false}
   event.emit("tell",Opponent.SHORT_NAME+" STEPS BACK" if ostate==25 else str(attack.name))
  if ostate==25:state="opening" if animation.m[0xba]!=0 else "taunt"
  else:
   state="windup" if opponent_age<int(attack.windup) else "recovery"
   state_ticks=maxi(0,int(attack.windup)-opponent_age)
 else:state="reaction"
 # The original collision handler resolves an incoming contact first.
 if (animation.m[0x98]|animation.m[0x58])&128:_resolve_contacts()
 animation.finish_tick()
 _sync_resources()
 animation.m[0x391]=hp;animation.m[0x398]=opponent_hp
 # $A8F6..$A8FF: after round initializer returns 1, wait two NMIs,
 # then request visibility; $AF73 acknowledges it on the following NMI.
 if round_entry_wait>0:
  round_entry_wait-=1
  if round_entry_wait==0:animation.m[0x1b]=129
 if state in ["player_down","opponent_down","countout"]:return
 round_centis=_source_clock()
 if animation.m[0]==255 and animation.m[5]==3:
  # Main-thread $A912 -> $BF7E: palette fade, then two eight-frame waits.
  if not post_bell_started:
   post_bell_started=true;animation.m[0x4c8]=64;release_all()
  elif animation.m[0x4c8]>0:
   if (animation.m[0x1e]&7)==0:
    animation.m[0x4c8]-=16
    pending_palette_fade=animation.m[0x4c8]
    round_fade=1.0-float(animation.m[0x4c8])/64.0
    if animation.m[0x4c8]==0:post_bell_wait=16
  elif post_bell_wait>0:post_bell_wait-=1
  if post_bell_wait!=0:return
  if round_number<3:
   state="between_rounds";release_all();_clear_player();_clear_opponent();event.emit("round","BELL — TAP A PUNCH TO CONTINUE")
  else:verdict="DECISION";finish("win" if points>=5000 else "loss")
func _source_clock() -> int:
 return animation.m[0x302]*6000+animation.m[0x304]*1000+animation.m[0x305]*100+animation.m[0x306]
func _sync_resources() -> void:
 var old_stars:=stars
 stars=animation.m[0x342]
 hearts=animation.m[0x323]*10+animation.m[0x324] if animation.m[0xbc]!=0 else 0
 points=0
 for address in range(0x3e8,0x3ee):points=points*10+animation.m[address]
 if stars>old_stars:event.emit("star","STAR EARNED — SPECIAL AVAILABLE")
func _begin_opponent(name: String) -> void:
 super._begin_opponent(name)
 animation.m[0x90]=opponent_action|128
func _opponent_frame() -> Dictionary:
 return {"defense":[animation.m[0xb6],animation.m[0xb7],animation.m[0xb8],animation.m[0xb9]],"ko":animation.m[0xba],"clock_pause":bool(animation.m[0x301]&1)}
func _player_defense(side: int) -> int:return animation.m[0x76+side]
func _resolve_player_contact() -> void:_resolve_contacts()
func resolve_strike() -> void:_resolve_contacts()
func _resolve_contacts() -> void:
 var incoming:=bool(animation.m[0x98]&128)
 var special:=bool(animation.m[0x74]&128)
 var before_hp:=hp
 var before_opponent:=opponent_hp
 var was_attacking:=opponent_action in [21,22]
 contact_vm.m=animation.m;contact_vm.step();animation.m=contact_vm.m
 if not contact_vm.error.is_empty():
  animation_failure=contact_vm.error;active=false;push_error(animation_failure);return
 hp=animation.m[0x391];opponent_hp=animation.m[0x398]
 if animation.m[0xbc]==0:hearts=0
 elif animation.m[0x321]+animation.m[0x322]!=0:hearts=animation.m[0x321]*10+animation.m[0x322]
 speed_wait=animation.m[0x581];star_hits_left=animation.m[0x347]
 if incoming:
  var outcome: int=animation.m[0x98]
  if outcome in [2,4]:avoids+=1;event.emit("evade","CLEAN SLIP!")
  elif outcome==1:avoids+=1;event.emit("guard","BLOCKED -%d" % (before_hp-hp))
  else:
   received+=1;event.emit("hurt","HIT -%d" % (before_hp-hp))
 else:
  var outcome: int=animation.m[0x58]
  if outcome==1:event.emit("blocked","BLOCKED - CHANGE YOUR TARGET")
  elif outcome==2:event.emit("miss","OUT OF REACH")
  elif outcome==3:
   hits+=1
   if was_attacking:counters+=1
   event.emit("counter" if was_attacking or special else "hit",("STAR UPPERCUT" if special else "CLEAN HIT")+" -%d" % (before_opponent-opponent_hp))
 if animation.m[5]!=0:_adopt_knockdown(animation.m[5]==1)
func _begin_knockdown(opponent: bool,instant_ko: bool) -> void:
 # Debug/test entry calls recovered count selection, just like contact.
 animation.m[0x391]=hp;animation.m[0x392]=hp
 animation.m[0x398]=opponent_hp;animation.m[0x399]=opponent_hp
 animation.m[6]=round_number;animation.m[0x302]=round_centis/6000
 animation.m=KnockdownEntry.apply(animation.m,opponent)
 if instant_ko:animation.m[0xba]=255
 contact_vm.m=animation.m;contact_vm.step(0xb2eb);animation.m=contact_vm.m
 animation.m[0x51]=129;animation.m[0x91]=129
 if not contact_vm.error.is_empty():animation_failure=contact_vm.error;active=false;push_error(animation_failure);return
 _adopt_knockdown(opponent)
func _adopt_knockdown(opponent: bool) -> void:
 _clear_player();_clear_opponent();release_all();reaction_ticks=0
 down_age=0;count=0;stand_at=-1;star_delay=0
 if opponent:
  opponent_downs=animation.m[0x3ca];state="opponent_down"
  getup_count=maxi(0,animation.m[0xc4]-153);recovered_hp=animation.m[0x39e]
  event.emit("knockdown",Opponent.SHORT_NAME+" IS DOWN - COUNTING")
 else:
  player_downs=animation.m[0x8f];player_total_downs=animation.m[0x3d0]
  state="countout" if animation.m[0xc0]==0 else "player_down"
  stars=0;getup_needed=animation.m[0x3c3];getup_decay=animation.m[0x3c4]
  event.emit("knockdown","YOU ARE DOWN - TAP LEFT / RIGHT TO RISE")
func _getup_press() -> bool:
 if animation.m[0xcf]==0 or (animation.m[0x3c3]&127)==0:return false
 queued_buttons|=128;queued_button_frames=2
 return true
func _step_knockdown() -> void:
 down_age+=1
 count=clampi(animation.m[0xc1]-153,0,10)
 hp=animation.m[0x391];opponent_hp=animation.m[0x398]
 getup_needed=animation.m[0x3c3]&127
 if state=="player_down" and animation.m[0x36]==2 and stand_at<0:
  stand_at=down_age;recovered_hp=animation.m[0x397];recovered_hearts=animation.m[0x322];event.emit("getup","ON YOUR FEET!")
 # Finish scripts signal through $00; $BB only coordinates actors.
 if animation.m[0] in [254,252,253,251]:
  verdict="TKO" if animation.m[0] in [252,251] else "KO"
  finish("win" if animation.m[0] in [254,252] else "loss")
 elif animation.m[5]==0:
  var player_recovered:=state=="player_down"
  state="ready";_clear_player();_clear_opponent();speed_wait=24;scheduler_delay=64;scheduler_pc=1
  if player_recovered:hearts=recovered_hearts
  event.emit("getup","BACK IN THE FIGHT")
func _next_round() -> void:
 var previous:PackedInt32Array=animation.m.duplicate()
 post_bell_started=false;post_bell_wait=-1;round_fade=0.0;pending_palette_fade=-1;round_entry_wait=-1
 round_scene_visible=false
 round_number+=1;state="ready";release_all();_clear_player();_clear_opponent()
 # $AB58..$AC37 logical round setup. Corner text/graphics remain original UI.
 animation.reset()
 for address in animation.geometry.fight_initial:animation.m[int(address)]=int(animation.geometry.fight_initial[address])
 var m:PackedInt32Array=animation.m
 for address in range(0x300,0x400):m[address]=previous[address]
 for address in [0x18,0x19,0x1e]:m[address]=previous[address]
 for address in range(0x40,0xf0):m[address]=0
 m[6]=round_number;m[5]=0;m[0]=48;m[0x1b]=0
 m[0xb0]=m[0x5ce];m[0xb1]=m[0x5cf]
 m[0x14]=1;m[0x16]=1;m[0x15]=176;m[0x13]=(176-m[0x5cc])&255
 m[0x310]=(m[0x310]-1)&255;m[0x311]=192;m[0x300]=0
 m[0x4fd]=0;m[0x4fe]=0;m[0x4ff]=0
 m[0x35]=0;m[0x36]=0;m[0x37]=128;m[0x39]=255;m[0x40]=129;m[0x3e0]=1
 m[0x397]=hp;m[0x39e]=opponent_hp
 m[0x392]=hp;m[0x393]=hp;m[0x399]=opponent_hp;m[0x39a]=opponent_hp
 m[0x30]=1;m[0x38]=1
 animation.m=m;animation.player_picture=58
 animation.opponent_picture=animation.opponent_compositor.compose(128,58,0,Vector2i(m[0xb0],m[0xb1]))
 animation.prime_display()
 _sync_resources();queued_buttons=0;queued_button_frames=0
 event.emit("round","ROUND %d" % round_number)
