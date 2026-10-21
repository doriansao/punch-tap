extends SceneTree
const Main=preload("res://scripts/main.gd")
func _initialize() -> void: call_deferred("capture")
func snap(name:String) -> void:
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("G:/Programming/punch-tap/research/evidence/godot_"+name+".png")
func reset_visuals(game) -> void:
 game.hit_flash=0;game.opponent_flash=0;game.block_flash=0;game.feedback_time=0
func capture() -> void:
 root.size=Vector2i(540,960)
 var game=Main.new();root.add_child(game);game.sound_on=false;game.set_physics_process(false)
 await snap("intro")
 game._start_or_resume()
 game.fight.act("head","left")
 for i in 11:game.fight.step()
 await snap("head_contact")
 game.fight.start()
 reset_visuals(game)
 game.fight._begin_opponent("taunt_long")
 game.fight.opponent_age=145;game.fight.state="opening"
 await snap("opening")
 game.fight.opponent_hp=0;game.fight._begin_knockdown(true,false)
 for i in 351:game.fight.step()
 await snap("opponent_down")
 game.fight.start();game.fight.hp=0;game.fight._begin_knockdown(false,false)
 reset_visuals(game)
 for i in 253:game.fight.step()
 await snap("player_down")
 game.fight.start();game.fight.stars=2
 reset_visuals(game)
 await snap("star_ready")
 quit()
