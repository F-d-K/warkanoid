extends Node2D

# Types: 0=wide, 1=multi, 2=fire, 3=slow, 4=laser
var ptype : int = 0
const FALL  : float = 95.0
var _time   : float = 0.0

const LABELS : Array[String] = ["WIDE", "MULTI", "FIRE", "SLOW", "LASR"]
const HUES   : Array[float]  = [0.33, 0.58, 0.02, 0.55, 0.75]

func _process(delta: float) -> void:
	_time      += delta
	position.y += FALL * delta
	if position.y > 650: queue_free()
	queue_redraw()

func _draw() -> void:
	var h   : float = HUES[ptype % HUES.size()]
	var col := Color.from_hsv(h, 0.9, 1.0)
	var glow_a := 0.15 + sin(_time * 5.0) * 0.08

	# Pulsing halo
	draw_arc(Vector2.ZERO, 18 + sin(_time*4)*2, 0, TAU, 32,
			 Color.from_hsv(h, 0.7, 1.0, glow_a), 6.0)

	# Hexagon body
	var pts := PackedVector2Array()
	for i in 6:
		var a := i * TAU / 6 - PI / 6
		pts.append(Vector2(cos(a) * 14, sin(a) * 14))
	var cols := PackedColorArray()
	for i in 6:
		cols.append(Color.from_hsv(fmod(h + float(i)*0.05, 1.0), 0.85, 0.95))
	draw_polygon(pts, cols)

	# Outline
	var o_pts := PackedVector2Array(pts)
	o_pts.append(o_pts[0])
	draw_polyline(o_pts, Color.from_hsv(fmod(h+0.5,1.0), 1.0, 1.0, 0.9), 1.5)
