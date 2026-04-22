extends Node2D

const SHADER = preload("res://shaders/plasma.gdshader")

var _mat      : ShaderMaterial
var _time     : float = 0.0
var _pulse    : float = 0.0
var _hue      : float = 0.0
var _speed    : float = 1.0
var _tgt_spd  : float = 1.0
var _rip_str  : float = 0.0
var _rip_pos  : Vector2 = Vector2(0.5, 0.5)
var _intensity: float = 1.0

func _ready() -> void:
	var rect := ColorRect.new()
	rect.size = Vector2(800, 600)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	rect.material = _mat
	add_child(rect)
	_push()

func _process(delta: float) -> void:
	_time    += delta
	_pulse    = maxf(0.0, _pulse   - delta * 2.5)
	_rip_str  = maxf(0.0, _rip_str - delta * 1.8)
	_speed    = lerpf(_speed,   _tgt_spd, delta * 1.5)
	_tgt_spd  = lerpf(_tgt_spd, 1.0,     delta * 0.5)
	_push()

func _push() -> void:
	_mat.set_shader_parameter("time",       _time)
	_mat.set_shader_parameter("pulse",      _pulse)
	_mat.set_shader_parameter("hue_offset", _hue)
	_mat.set_shader_parameter("speed_mult", _speed)
	_mat.set_shader_parameter("ripple_str", _rip_str)
	_mat.set_shader_parameter("ripple_pos", _rip_pos)
	_mat.set_shader_parameter("intensity",  _intensity)

# ── Event hooks ──────────────────────────────────────────────────────────────

func on_bounce(pos: Vector2) -> void:
	_rip_pos = Vector2(pos.x / 800.0, pos.y / 600.0)
	_rip_str = minf(_rip_str + 0.5, 2.0)
	_pulse   = minf(_pulse   + 0.15, 1.2)
	_speed   = minf(_speed   + 0.2,  3.0)

func on_brick(pos: Vector2) -> void:
	_rip_pos = Vector2(pos.x / 800.0, pos.y / 600.0)
	_rip_str = minf(_rip_str + 0.9, 2.8)
	_pulse   = minf(_pulse   + 0.5, 2.0)
	_speed   = minf(_speed   + 0.4, 4.0)
	_hue     = fmod(_hue + 0.08, 1.0)

func on_powerup() -> void:
	_hue     = fmod(_hue + 0.25, 1.0)
	_tgt_spd = 3.0
	_pulse   = minf(_pulse + 0.8, 2.0)

func on_die() -> void:
	_pulse    = 2.5
	_tgt_spd  = 5.0
	_hue      = fmod(_hue + 0.5, 1.0)

func on_level_up() -> void:
	_hue      = fmod(_hue + 0.33, 1.0)
	_tgt_spd  = 4.0
	_pulse    = 1.8
	_intensity = 1.6

func set_intensity(v: float) -> void:
	_intensity = v
