extends RefCounted
## Cosmetic, time-based effects only. Never writes fight state or the ROM clock.
var bursts: Array = []
var cheer := 0.0
var time := 0.0

func advance(delta: float) -> void:
	time += delta
	cheer = maxf(0, cheer - delta)
	for burst in bursts: burst.age += delta
	bursts = bursts.filter(func(b): return b.age < b.life)

func impact(at: Vector2, strong: bool, hurt: bool = false) -> void:
	bursts.append({"at":at, "age":0.0, "life":0.48 if strong else 0.28,
		"size":72.0 if strong else 42.0, "color":Color("ff7852") if hurt else Color("ffdc72")})
	cheer = maxf(cheer, 0.6)

func crowd(canvas: CanvasItem) -> void:
	for row in 2:
		for i in 17:
			var phase := time * (12.0 if cheer > 0 else 2.0) + i * 1.7 + row
			var lift := absf(sin(phase)) * (12.0 if cheer > 0 else 1.5)
			var p := Vector2(i * 34 - 3 + row * 14, 267 + row * 23 - lift)
			var shirt: Color = [Color("39837f"),Color("da7953"),Color("e3bb73")][i % 3]
			canvas.draw_line(p + Vector2(0,7), p + Vector2(0,23), Color("101c2c"), 19)
			canvas.draw_line(p + Vector2(0,7), p + Vector2(0,22), shirt, 13)
			canvas.draw_circle(p, 8, Color("101c2c"))
			canvas.draw_circle(p, 6, Color("c99878"))
			if cheer > 0:
				for side in [-1,1]:
					canvas.draw_line(p+Vector2(side*5,10),p+Vector2(side*13,-8-lift*.3),shirt,5)

func effects(canvas: CanvasItem) -> void:
	for burst in bursts:
		var t: float = burst.age / burst.life
		var color: Color = burst.color
		color.a = 1.0-t
		if t < 0.35:
			var points := PackedVector2Array()
			for i in 20:
				var radius: float = (22.0 if i % 2 == 0 else 9.0) * (1.0 + t)
				points.append(burst.at + Vector2.from_angle(i * TAU / 20.0) * radius)
			canvas.draw_colored_polygon(points, Color("fff2c4"))
		for i in 10:
			var direction := Vector2.from_angle(i * TAU / 10.0 + 0.2)
			canvas.draw_line(burst.at + direction * (8+t*burst.size), burst.at + direction * (22+t*burst.size*1.7),color,4*(1-t)+1,true)
		canvas.draw_arc(burst.at, 6+t*burst.size,0,TAU,32,color,3*(1-t)+1,true)
