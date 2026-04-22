extends Node2D

const RADIUS   : float = 11.0
const SPEED    : float = 75.0

const BL : float = 34.0
const BR : float = 766.0
const BT : float = 60.0
const BB : float = 490.0

var velocity : Vector2 = Vector2.ZERO
var _time    : float   = 0.0
var _steer_t : float   = 0.0
var _flash   : float   = 0.0

func _ready() -> void:
	var a := randf() * TAU
	velocity = Vector2(cos(a), sin(a)) * SPEED
	_steer_t = randf_range(0.8, 2.5)

func _process(delta: float) -> void:
	_time   += delta
	_flash   = maxf(0.0, _flash - delta * 6.0)
	_steer_t -= delta

	if _steer_t <= 0.0:
		var a := randf() * TAU
		velocity = velocity.lerp(Vector2(cos(a), sin(a)) * SPEED, 0.55)
		if velocity.length() < SPEED * 0.7:
			velocity = velocity.normalized() * SPEED
		_steer_t = randf_range(1.2, 3.0)

	position += velocity * delta

	if position.x - RADIUS < BL:
		position.x = BL + RADIUS
		velocity.x = absf(velocity.x)
	if position.x + RADIUS > BR:
		position.x = BR - RADIUS
		velocity.x = -absf(velocity.x)
	if position.y - RADIUS < BT:
		position.y = BT + RADIUS
		velocity.y = absf(velocity.y)
	if position.y + RADIUS > BB:
		position.y = BB - RADIUS
		velocity.y = -absf(velocity.y)

	queue_redraw()

func _draw() -> void:
	var r     : float = RADIUS
	var spin  : float = _time * 1.8
	var pulse : float = 0.5 + 0.5 * sin(_time * 5.0)
	var hue   : float = 0.82  # violet/magenta

	# Outer glow halo
	draw_circle(Vector2.ZERO, r + 7.0,
		Color.from_hsv(hue, 0.85, 1.0, 0.08 + pulse * 0.10 + _flash * 0.30))

	# Rotating diamond body
	var pts := PackedVector2Array()
	for i in 4:
		var a := spin + i * PI * 0.5
		pts.append(Vector2(cos(a), sin(a)) * r)
	var c0 := Color.from_hsv(hue,        0.90, 1.00)
	var c1 := Color.from_hsv(hue + 0.06, 0.65, 1.00)
	draw_polygon(pts, PackedColorArray([c0, c1, c0, c1]))

	# Edges
	for i in 4:
		var a0 := spin + i * PI * 0.5
		var a1 := spin + (i + 1) * PI * 0.5
		draw_line(Vector2(cos(a0), sin(a0)) * r,
		          Vector2(cos(a1), sin(a1)) * r,
		          Color(1.0, 1.0, 1.0, 0.45 + _flash * 0.4), 1.5)

	# Inner core
	draw_circle(Vector2.ZERO, r * 0.38,
		Color.from_hsv(hue, 0.20, 1.0, 0.95))

	# Flash hit-white
	if _flash > 0.05:
		draw_circle(Vector2.ZERO, r + 5.0, Color(1, 1, 1, _flash * 0.45))
