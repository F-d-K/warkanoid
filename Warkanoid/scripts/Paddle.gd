extends Node2D

const WIDTH   : float = 90.0
const HEIGHT  : float = 14.0
const HALF_W  : float = WIDTH  * 0.5
const HALF_H  : float = HEIGHT * 0.5
const P2_SPEED: float = 520.0

# Set by Game before _ready runs
var player_id : int   = 1
var min_x     : float = HALF_W + 10
var max_x     : float = 790 - HALF_W

var _time   : float = 0.0
var _hue    : float = 0.0
var _glow   : float = 0.0

var rect : Rect2 :
	get: return Rect2(position.x - HALF_W, position.y - HALF_H, WIDTH, HEIGHT)

func _process(delta: float) -> void:
	_time += delta
	_glow  = maxf(0.0, _glow - delta * 4.0)

	if player_id == 1:
		_hue = fmod(_time * 0.4, 1.0)
		var mx := get_viewport().get_mouse_position().x
		position.x = clamp(mx, min_x, max_x)
	else:
		_hue = 0.55  # fixed cyan
		var dir := Input.get_axis("ui_left", "ui_right")
		position.x = clamp(position.x + dir * P2_SPEED * delta, min_x, max_x)

	queue_redraw()

func flash() -> void:
	_glow = 1.0

func _draw() -> void:
	var hue  := _hue
	var glow := _glow

	# Outer halo
	for r in [HALF_W + 10, HALF_W + 6, HALF_W + 2]:
		var alpha := 0.06 + glow * 0.12
		draw_rect(Rect2(-r, -HALF_H - 4, r * 2, HEIGHT + 8),
				  Color.from_hsv(hue, 0.9, 1.0, alpha))

	# Body gradient
	var c1 := Color.from_hsv(hue,                  0.7, 1.0)
	var c2 := Color.from_hsv(fmod(hue + 0.15, 1.0), 0.9, 1.0)
	var c3 := Color.from_hsv(fmod(hue + 0.30, 1.0), 0.8, 0.9)
	var pts := PackedVector2Array([
		Vector2(-HALF_W,  HALF_H),
		Vector2(-HALF_W, -HALF_H),
		Vector2( HALF_W, -HALF_H),
		Vector2( HALF_W,  HALF_H),
	])
	draw_polygon(pts, PackedColorArray([c1, c2, c3, c1]))

	# Top highlight streak
	draw_rect(Rect2(-HALF_W + 4, -HALF_H + 2, WIDTH - 8, 3),
			  Color(1, 1, 1, 0.35 + glow * 0.4))

	# Edge neon lines
	var ec := Color.from_hsv(fmod(hue + 0.5, 1.0), 1.0, 1.0, 0.9 + glow * 0.1)
	draw_line(Vector2(-HALF_W, -HALF_H), Vector2( HALF_W, -HALF_H), ec, 1.5)
	draw_line(Vector2(-HALF_W,  HALF_H), Vector2( HALF_W,  HALF_H), ec, 1.5)

	var gem_c := Color.from_hsv(fmod(hue + 0.5, 1.0), 0.6, 1.0, 0.9)
	if player_id == 1:
		# Diamond gem
		var gem := PackedVector2Array([
			Vector2( 0, -5), Vector2( 6,  0),
			Vector2( 0,  5), Vector2(-6,  0),
		])
		draw_polygon(gem, PackedColorArray([gem_c, gem_c, gem_c, gem_c]))
	else:
		# Square gem + bracket decorations at both ends
		draw_rect(Rect2(-5, -5, 10, 10), gem_c)
		var nc := Color.from_hsv(hue, 0.6, 1.0, 0.85)
		# Left bracket
		draw_line(Vector2(-HALF_W + 4, -HALF_H + 2), Vector2(-HALF_W + 4,  HALF_H - 2), nc, 2.0)
		draw_line(Vector2(-HALF_W + 4, -HALF_H + 2), Vector2(-HALF_W + 10, -HALF_H + 2), nc, 1.5)
		draw_line(Vector2(-HALF_W + 4,  HALF_H - 2), Vector2(-HALF_W + 10,  HALF_H - 2), nc, 1.5)
		# Right bracket
		draw_line(Vector2(HALF_W - 4, -HALF_H + 2), Vector2(HALF_W - 4,  HALF_H - 2), nc, 2.0)
		draw_line(Vector2(HALF_W - 4, -HALF_H + 2), Vector2(HALF_W - 10, -HALF_H + 2), nc, 1.5)
		draw_line(Vector2(HALF_W - 4,  HALF_H - 2), Vector2(HALF_W - 10,  HALF_H - 2), nc, 1.5)
