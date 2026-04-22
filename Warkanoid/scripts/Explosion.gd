extends Node2D

var col    : Color  = Color.WHITE
var _time  : float  = 0.0
var _life  : float  = 0.55
var _parts : Array  = []   # [{pos, vel, hue, size}]

func _ready() -> void:
	var base_hue := col.h
	for i in 22:
		var angle := randf() * TAU
		var spd   := randf_range(30.0, 160.0)
		_parts.append({
			"pos":  Vector2.ZERO,
			"vel":  Vector2(cos(angle), sin(angle)) * spd,
			"hue":  fmod(base_hue + randf_range(-0.15, 0.15), 1.0),
			"size": randf_range(2.5, 6.0),
		})

func _process(delta: float) -> void:
	_time += delta
	if _time >= _life:
		queue_free()
		return
	for p in _parts:
		p["pos"] += (p["vel"] as Vector2) * delta
		p["vel"]  = (p["vel"] as Vector2) * (1.0 - delta * 3.5)
	queue_redraw()

func _draw() -> void:
	var t := _time / _life
	for p in _parts:
		var a := (1.0 - t) * (1.0 - t)
		var s := (p["size"] as float) * (1.0 - t * 0.5)
		draw_circle(p["pos"] as Vector2,
					s,
					Color.from_hsv(p["hue"] as float, 0.9, 1.0, a))
	# Central flash
	if t < 0.25:
		draw_circle(Vector2.ZERO, 14 * (1.0 - t / 0.25),
					Color(1, 1, 1, (1.0 - t / 0.25) * 0.6))
