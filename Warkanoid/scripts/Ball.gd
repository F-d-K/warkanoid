extends Node2D

const RADIUS   : float = 7.0
const MAX_TRAIL: int   = 28

var velocity   : Vector2 = Vector2.ZERO
var active     : bool    = false
var _time      : float   = 0.0
var _hue       : float   = 0.0
var _trail     : Array   = []   # Array of Vector2

func _process(delta: float) -> void:
	_time += delta
	_hue   = fmod(_time * 0.7, 1.0)

	if active:
		_trail.push_front(position)
		if _trail.size() > MAX_TRAIL:
			_trail.pop_back()
	queue_redraw()

func _draw() -> void:
	# Trail
	for i in _trail.size():
		var tp : Vector2 = (_trail[i] as Vector2) - position
		var t  : float   = 1.0 - float(i) / MAX_TRAIL
		var r  : float   = RADIUS * t * 0.85
		var h  : float   = fmod(_hue - float(i) * 0.04, 1.0)
		draw_circle(tp, r, Color.from_hsv(h, 0.9, 1.0, t * t * 0.55))

	# Outer glow rings
	for ri in 3:
		var gr : float = RADIUS + 3.0 + float(ri) * 3.0
		draw_arc(Vector2.ZERO, gr, 0, TAU, 24,
				 Color.from_hsv(_hue, 0.8, 1.0, 0.10 - ri * 0.03), 2.0)

	# Core
	var core_c := Color.from_hsv(_hue, 0.5, 1.0)
	draw_circle(Vector2.ZERO, RADIUS, core_c)

	# Specular highlight
	draw_circle(Vector2(-2, -2), RADIUS * 0.38, Color(1, 1, 1, 0.7))
