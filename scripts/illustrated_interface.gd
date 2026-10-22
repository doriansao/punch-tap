extends RefCounted
## Generated art is immutable; Godot handles atlas regions, fills and input states.
var atlas: Texture2D = preload("res://assets/cartoon/interface/controls_v1.png")
var ring: Texture2D = preload("res://assets/cartoon/interface/rooftop_ring_v2.png")
var regions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/cartoon/interface/regions.json"))
var textures: Dictionary = {}
func texture(key: String) -> AtlasTexture:
	if not textures.has(key):
		var t := AtlasTexture.new()
		t.atlas = atlas
		var r: Array = regions[key]
		t.region = Rect2(r[0],r[1],r[2],r[3])
		textures[key] = t
	return textures[key]
func icon(canvas: CanvasItem, key: String, rect: Rect2, tint := Color.WHITE) -> void:
	canvas.draw_texture_rect(texture(key),rect,false,tint)
func skin(button: Button, key: String, hint: String) -> void:
	button.text = ""
	button.tooltip_text = hint
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = texture(key)
		style.modulate_color = Color(0.76,0.76,0.76) if state == "pressed" else (Color(0.4,0.4,0.4) if state == "disabled" else Color.WHITE)
		button.add_theme_stylebox_override(state,style)
func meter(canvas: CanvasItem, rect: Rect2, fraction: float, color: Color) -> void:
	var r: Array = regions.bar
	var cap := 80.0*rect.size.y/float(r[3])
	canvas.draw_texture_rect_region(atlas,Rect2(rect.position,Vector2(cap,rect.size.y)),Rect2(r[0],r[1],80,r[3]))
	canvas.draw_texture_rect_region(atlas,Rect2(rect.position+Vector2(cap,0),Vector2(rect.size.x-2*cap,rect.size.y)),Rect2(float(r[0])+80,r[1],float(r[2])-160,r[3]))
	canvas.draw_texture_rect_region(atlas,Rect2(rect.end-Vector2(cap,rect.size.y),Vector2(cap,rect.size.y)),Rect2(float(r[0])+float(r[2])-80,r[1],80,r[3]))
	# Fill sits inside the generated empty capsule; never stretches the end caps.
	var inner := Rect2(rect.position+Vector2(cap,rect.size.y*0.23),Vector2(rect.size.x-2*cap,rect.size.y*0.54))
	inner.size.x *= clampf(fraction,0,1)
	if inner.size.x > 0:
		var fill := StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(6)
		canvas.draw_style_box(fill,inner)
		canvas.draw_line(inner.position+Vector2(5,3),inner.position+Vector2(maxf(5,inner.size.x-5),3),color.lightened(0.4),2,true)

func card(canvas: CanvasItem, rect: Rect2) -> void:
	var panel:=StyleBoxFlat.new()
	panel.bg_color=Color("142b38");panel.border_color=Color("cba56b")
	panel.set_border_width_all(2);panel.border_width_bottom=4
	panel.set_corner_radius_all(14);panel.shadow_color=Color(0,0,0,0.45);panel.shadow_size=5
	canvas.draw_style_box(panel,rect)
	canvas.draw_line(rect.position+Vector2(17,7),Vector2(rect.end.x-17,rect.position.y+7),Color("365563"),2,true)
