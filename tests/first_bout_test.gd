extends SceneTree
const Fight=preload("res://scripts/fight_model_vm.gd")
func _initialize() -> void:
 var failures:=0
 # No health/resource fixtures: exploit the source opponent's return opening.
 var f=Fight.new();f.start(1)
 for tick in 5000:
  if f.opponent_action==25 and f.opponent_age==136:f.act("head","left");f.release("left")
  f.step()
  if not f.active:break
 if f.result!="win" or f.verdict!="KO":failures+=1
 print("Natural opening: ",f.result," ",f.verdict," at ",f.ticks," frames; error=",f.animation_failure)
 for interval in [25,30,35,40,45,50,60]:
  f=Fight.new();f.start(1)
  var saw_star:=false
  for tick in 25000:
   if f.state=="between_rounds":f.act("head","left");f.release("left")
   elif f.state=="player_down" and tick%8==0:f.act("head","left");f.release("left")
   elif tick%interval==0 and f.state not in ["taunt","opening","opponent_down","countout"]:
    var hand: String="left" if (tick/interval)%2==0 else "right"
    f.act("special" if f.stars>0 else "head",hand);f.release("special");f.release(hand)
   f.step()
   saw_star=saw_star or f.stars>0
   if not f.active:break
  print("Natural interval ",interval,": ",f.result," ",f.verdict," star=",saw_star," hits=",f.hits," downs=",f.opponent_downs," frame=",f.ticks," error=",f.animation_failure)
  if not f.animation_failure.is_empty() or f.active or not saw_star:failures+=1
 quit(1 if failures else 0)
