extends SceneTree
const Machine=preload("res://scripts/recovered/animation_machine.gd")
const Rng=preload("res://scripts/recovered/nes_animation_rng.gd")
func _initialize() -> void:
 var machine=Machine.new()
 for i in 1800:
  var r: Vector2i=Rng.advance((40+i)&255,0,machine.m[0x19])
  machine.m[0x18]=r.x;machine.m[0x19]=r.y
  machine.tick()
  if not machine.error.is_empty():
   push_error("Frame %d: %s" % [i,machine.error]);quit(1);return

 for action in [9,10,11,12,13,3,5,7]:
  machine.reset();machine.m[0x50]=action|128
  var finished:=false
  for frame in 240:
   machine.tick()
   if machine.m[0x58]&128:
    var blocked: bool=action in [9,10]
    machine.m[0x58]=1 if blocked else 3
    machine.m[0x90]=(7 if blocked else (2 if action==13 else (13 if action==11 else 14)))|128
   if machine.m[0x98]&128:machine.m[0x98]=3
   if not machine.error.is_empty():
    push_error("Action %d frame %d: %s" % [action,frame,machine.error]);quit(1);return
   if frame>5 and machine.m[0x50] in [1,129]:finished=true;break
  if not finished:push_error("Action %d did not return to idle" % action);quit(1);return

 for action in [11,12]:
  machine.reset();machine.m[0x50]=action|128
  var down:=false;var finished:=false
  for frame in 1200:
   machine.tick()
   if machine.m[0x58]&128 and not down:
    machine.m[0x58]=3;machine.m[0x90]=(13 if action==11 else 14)|128
    machine.begin_knockdown(true,6,80);down=true
   if not machine.error.is_empty():push_error("KD %d frame %d: %s" % [action,frame,machine.error]);quit(1);return
   if down and machine.m[5]==0:finished=true;print("Opponent KD hand ",action," returned after ",frame," ticks");break
  if not finished:push_error("Opponent knockdown did not finish: %d state %d / %d cursor %d / %d BB %d" % [action,machine.m[0x50],machine.m[0x90],machine.m[0x53],machine.m[0x93],machine.m[0xbb]]);quit(1);return
 machine.reset();machine.m[0x90]=149
 var player_down:=false;var got_up:=false
 for frame in 1400:
  machine.tick()
  if machine.m[0x98]&128 and not player_down:
   machine.m[0x98]=3;machine.m[0x50]=144;machine.begin_knockdown(false);player_down=true
  if machine.m[0xcf] and frame%8==0:machine.m[0xd5]=128
  if not machine.error.is_empty():push_error("Player KD frame %d: %s" % [frame,machine.error]);quit(1);return
  if player_down and machine.m[5]==0:got_up=true;print("Player got up after ",frame," ticks");break
 if not got_up:push_error("Player get-up did not finish: states %d / %d BB %d" % [machine.m[0x50],machine.m[0x90],machine.m[0xbb]]);quit(1);return
 print("Coupled animation machine: idle, 8 actions, both opponent falls and player get-up complete without captured-clip playback")
 quit()
