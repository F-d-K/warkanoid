extends Node2D

const SCAN_SHADER = preload("res://shaders/scanlines.gdshader")

@onready var background  = $Background
@onready var score_lbl   : Label         = $UI/ScoreLabel
@onready var level_lbl   : Label         = $UI/LevelLabel
@onready var rows_box    : VBoxContainer = $UI/ScoreRows
@onready var scan_rect   : ColorRect     = $Scanlines/ScanRect

var _time         : float = 0.0
var _scan_mat     : ShaderMaterial
var _player_score : int   = 0

func _ready() -> void:
	_player_score = GameManager.score
	GameManager.record_final_score()

	score_lbl.text = "SCORE  %07d" % _player_score
	level_lbl.text = "REACHED  LEVEL  %d" % GameManager.level

	_build_scores()

	# Splash — load raw PNG, bypass ResourceLoader import requirement
	_add_splash(Vector2(134, 318), 245.0, 360.0)

	# Scanlines overlay
	_scan_mat = ShaderMaterial.new()
	_scan_mat.shader = SCAN_SHADER
	_scan_mat.set_shader_parameter("scan_dark", GameManager.scan_strength * 0.6)
	scan_rect.material = _scan_mat

	background.on_die()
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
	_scan_mat.set_shader_parameter("time", _time)

func _build_scores() -> void:
	var ranks : Array[String] = ["1ST", "2ND", "3RD", "4TH", "5TH"]
	var hues  : Array[float]  = [0.13, 0.55, 0.58, 0.72, 0.80]
	var found_new : bool = false
	for i in mini(5, GameManager.hi_scores.size()):
		var s        : int    = GameManager.hi_scores[i]
		var is_new   : bool   = (not found_new) and (s == _player_score) and (s > 0)
		if is_new: found_new = true
		var hue      : float  = hues[i]
		var score_str: String = "-------" if s == 0 else "%07d" % s
		var suffix   : String = "  ◄" if is_new else ""
		var row               := Label.new()
		row.text = "%s   %s%s" % [ranks[i], score_str, suffix]
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_font_size_override("font_size", 21)
		var col : Color
		if is_new:
			col = Color.from_hsv(0.14, 0.9, 1.0)
		else:
			col = Color.from_hsv(hue, 0.55, 0.88 - float(i) * 0.07)
		row.add_theme_color_override("font_color", col)
		rows_box.add_child(row)

func _on_play_again() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_menu() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
