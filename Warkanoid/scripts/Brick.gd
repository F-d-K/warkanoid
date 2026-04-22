extends Node2D

signal destroyed(pos, points)

const W : float = 56.0
const H : float = 22.0

var hp       : int   = 1
var max_hp   : int   = 1
var points   : int   = 10
var col_idx  : int   = 0

var _time    : float = 0.0
var _flash   : float = 0.0
var _shake   : float = 0.0

const HUES : Array[float] = [0.0, 0.09, 0.17, 0.60, 0.50, 0.85]

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	_time  += delta
	_flash  = maxf(0.0, _flash - delta * 6.0)
	_shake  = maxf(0.0, _shake - delta * 8.0)
	queue_redraw()

func hit() -> bool:
	hp -= 1
	_flash = 1.0
	_shake = 1.0
	if hp <= 0:
		emit_signal("destroyed", position, points)
		queue_free()
		return true
	return false

func _draw() -> void:
	var hw : float = W * 0.5
	var hh : float = H * 0.5
	var ox : float = sin(_time * 18.0) * _shake * 2.0
	var oy : float = cos(_time * 23.0) * _shake * 1.5

	var base_hue : float = HUES[col_idx % HUES.size()]
	var hp_frac  : float = float(hp) / float(max_hp)
	var is_indestr : bool = (hp >= 99)

	# Glow halo (always visible, pulses)
	var glow_a : float = 0.12 + sin(_time * 4.0) * 0.04 + _flash * 0.35
	draw_rect(Rect2(ox - hw - 3, oy - hh - 3, W + 6, H + 6),
			  Color.from_hsv(base_hue, 0.9, 1.0, glow_a))

	# Shadow
	draw_rect(Rect2(ox - hw + 2, oy - hh + 2, W, H), Color(0, 0, 0, 0.5))

	# Main body
	var sat : float = 0.0 if is_indestr else 0.85
	var c0 := Color.from_hsv(base_hue,              sat,        0.9 * hp_frac + 0.1)
	var c1 := Color.from_hsv(base_hue,              sat * 0.9,  0.8 * hp_frac + 0.15)
	var c2 := Color.from_hsv(base_hue,              sat * 0.85, 0.7 * hp_frac + 0.2)
	var c3 := Color.from_hsv(base_hue,              sat * 0.95, 0.85* hp_frac + 0.1)
	var pts := PackedVector2Array([
		Vector2(ox - hw, oy + hh),
		Vector2(ox - hw, oy - hh),
		Vector2(ox + hw, oy - hh),
		Vector2(ox + hw, oy + hh),
	])
	draw_polygon(pts, PackedColorArray([c0, c1, c2, c3]))

	# Flash overlay
	if _flash > 0.05:
		draw_rect(Rect2(ox - hw, oy - hh, W, H), Color(1, 1, 1, _flash * 0.5))

	# Top sheen
	draw_rect(Rect2(ox - hw + 3, oy - hh + 2, W - 6, 4),
			  Color(1, 1, 1, 0.3 + _flash * 0.2))

	# Bold white border — always visible
	draw_rect(Rect2(ox - hw, oy - hh, W, H), Color(1, 1, 1, 0.55 + _flash * 0.4), false, 2.0)

	# HP pip dots
	if max_hp > 1 and max_hp < 99:
		for i in max_hp:
			var pip_c := Color.from_hsv(base_hue, 0.5, 1.0) if i < hp else Color(0.15, 0.15, 0.15, 0.7)
			draw_circle(Vector2(ox - float(max_hp - 1) * 4.0 + i * 8.0, oy + hh - 5), 2.5, pip_c)
