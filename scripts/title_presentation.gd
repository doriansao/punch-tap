extends RefCounted
## Authored menu motion; never used for combat or ROM pose selection.
var logo: Texture2D=preload("res://assets/cartoon/interface/title_logo_v1.png")
func draw(game, time: float) -> void:
 game._draw_arena()
 game.draw_rect(Rect2(0,0,540,960),Color(0.02,0.05,0.09,0.45))
 for i in 12:
  var angle:=float(i)*TAU/12+time*0.035
  var origin:=Vector2(270,300)
  game.draw_colored_polygon(PackedVector2Array([origin,origin+Vector2.from_angle(angle)*900,origin+Vector2.from_angle(angle+0.07)*900]),Color(0.3,0.95,0.75,0.035))
 actor(game,"opponent",24,Vector2(310,735),325.0,sin(time*2.0)*3)
 actor(game,"player",24,Vector2(188,785),178.0,sin(time*2.0+1)*2)
 var t:=clampf(time/0.8,0,1)
 var settle:=1.0+pow(t-1,3)*2.70158+pow(t-1,2)*1.70158
 var scale:=maxf(0.05,settle)*(1.0+0.012*sin(time*2))
 game.draw_set_transform(Vector2(270,267+sin(time*1.6)*6),sin(time*1.1)*0.012,Vector2.ONE*scale)
 game.draw_texture_rect(logo,Rect2(-260,-173,520,346),false)
 game.draw_set_transform(Vector2.ZERO)
 game.centered("TEO  vs  NICO",811,15,game.PAPER)
func actor(game, role: String, pose: int, feet: Vector2, height: float, bob: float) -> void:
 var r: Dictionary=game.art_registration[role][pose]
 var texture: Texture2D=load(r.texture)
 var region:=Rect2(r.region[0],r.region[1],r.region[2],r.region[3])
 var scale:=height/region.size.y
 game.draw_set_transform(feet-Vector2(0,height+bob))
 game.isolated_sprite.draw(game,texture,r,region,region.size.x*scale,scale)
 game.draw_set_transform(Vector2.ZERO)
