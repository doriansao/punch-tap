extends RefCounted
## Original presentation only. Recovered combat rules remain independent.
const NAME = "Nico ‘Rivet’ Reyes"
const SHORT_NAME = "NICO"
const SPRITE_PATH = "res://assets/nico_front.png"
# Explicit regions keep the lower-row recoil glove inside its own frame.
const REGIONS: Array[Rect2] = [
	Rect2(0, 0, 384, 512), Rect2(384, 0, 384, 512),
	Rect2(768, 0, 384, 512), Rect2(1152, 0, 384, 512),
	Rect2(0, 520, 384, 504), Rect2(384, 520, 400, 504),
	Rect2(800, 520, 352, 504), Rect2(1152, 520, 384, 504)]
