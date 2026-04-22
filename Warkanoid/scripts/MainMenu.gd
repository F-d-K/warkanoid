extends Node2D

const SHADER      = preload("res://shaders/plasma.gdshader")
const SCAN_SHADER = preload("res://shaders/scanlines.gdshader")

@onready var scan_rect : ColorRect = $Scanlines/ScanRect
@onready var hi_lbl    : Label     = $UI/HiScore

var _mat      : ShaderMaterial
var _scan_mat : ShaderMaterial
var _time     : float = 0.0

func _ready() -> void:
	# Plasma background
	var rect := ColorRect.new()
	rect.size = Vector2(800, 600)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("intensity", 1.4)
	rect.material = _mat
	$Background.add_child(rect)

	# Splash — load raw PNG, bypass ResourceLoader import requirement
	_add_splash(Vector2(154, 310), 280.0, 470.0)

	# Scanlines overlay
	_scan_mat = ShaderMaterial.new()
	_scan_mat.shader = SCAN_SHADER
	_scan_mat.set_shader_parameter("scan_dark", GameManager.scan_strength * 0.6)
	scan_rect.material = _scan_mat

	hi_lbl.text = "%07d" % GameManager.hi_score
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _add_splash(center: Vector2, max_w: float, max_h: float) -> void:
	var tex : Texture2D = load("res://splash.png")
	if tex == null:
		return
	var spr            := Sprite2D.new()
	spr.texture         = tex
	spr.z_index         = 2
	var sc : float      = minf(max_w / float(tex.get_width()),
	                           max_h / float(tex.get_height()))
	spr.scale           = Vector2(sc, sc)
	spr.position        = center
	add_child(spr)

func _process(delta: float) -> void:
	_time += delta
	_mat.set_shader_parameter("time",       _time)
	_mat.set_shader_parameter("hue_offset", fmod(_time * 0.05, 1.0))
	_mat.set_shader_parameter("speed_mult", 1.2)
	_mat.set_shader_parameter("pulse",      0.3 + sin(_time * 1.5) * 0.15)
	_scan_mat.set_shader_parameter("time",  _time)

func _on_play_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Options.tscn")

func _on_editor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/LevelEditor.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
