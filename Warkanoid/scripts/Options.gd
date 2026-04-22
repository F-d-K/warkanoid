extends Node2D

const SCAN_SHADER = preload("res://shaders/scanlines.gdshader")

@onready var fs_btn        : Button    = $UI/FsBtn
@onready var int_slider    : HSlider   = $UI/IntSlider
@onready var int_val_lbl   : Label     = $UI/IntValLbl
@onready var spc_slider    : HSlider   = $UI/SpacingSlider
@onready var spc_val_lbl   : Label     = $UI/SpacingValLbl
@onready var scan_rect     : ColorRect = $Scanlines/ScanRect

var _scan_mat : ShaderMaterial

func _ready() -> void:
	# Scanlines overlay — set BEFORE syncing sliders
	_scan_mat = ShaderMaterial.new()
	_scan_mat.shader = SCAN_SHADER
	_scan_mat.set_shader_parameter("scan_dark",  GameManager.scan_strength * 0.6)
	_scan_mat.set_shader_parameter("scan_count", GameManager.scan_count_setting)
	scan_rect.material = _scan_mat

	# Sync controls to saved settings without triggering callbacks
	fs_btn.set_pressed_no_signal(GameManager.fullscreen)
	fs_btn.text = "ON" if GameManager.fullscreen else "OFF"

	int_slider.set_block_signals(true)
	int_slider.value = GameManager.scan_strength
	int_slider.set_block_signals(false)
	int_val_lbl.text = _intensity_text(GameManager.scan_strength)

	spc_slider.set_block_signals(true)
	spc_slider.value = GameManager.scan_count_setting
	spc_slider.set_block_signals(false)
	spc_val_lbl.text = _spacing_text(GameManager.scan_count_setting)

	# Splash
	_add_splash(Vector2(129, 310), 240.0, 450.0)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _add_splash(center: Vector2, max_w: float, max_h: float) -> void:
	var tex : Texture2D = load("res://splash.png")
	if tex == null:
		return
	var spr        := Sprite2D.new()
	spr.texture     = tex
	spr.z_index     = 2
	var sc : float  = minf(max_w / float(tex.get_width()),
	                       max_h / float(tex.get_height()))
	spr.scale       = Vector2(sc, sc)
	spr.position    = center
	add_child(spr)

func _intensity_text(v: float) -> String:
	return "OFF" if v < 0.01 else "%d%%" % int(v * 100.0)

func _spacing_text(v: float) -> String:
	if v >= 450.0: return "FINE"
	if v >= 270.0: return "MED"
	if v >= 140.0: return "COARSE"
	return "CHUNKY"

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	GameManager.fullscreen = toggled_on
	fs_btn.text = "ON" if toggled_on else "OFF"
	GameManager.apply_display()
	GameManager.save_settings()

func _on_intensity_changed(value: float) -> void:
	GameManager.scan_strength = value
	_scan_mat.set_shader_parameter("scan_dark", value * 0.6)
	int_val_lbl.text = _intensity_text(value)

func _on_spacing_changed(value: float) -> void:
	GameManager.scan_count_setting = value
	_scan_mat.set_shader_parameter("scan_count", value)
	spc_val_lbl.text = _spacing_text(value)

func _on_back() -> void:
	GameManager.save_settings()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
