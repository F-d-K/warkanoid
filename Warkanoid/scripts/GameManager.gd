extends Node

var score              : int   = 0
var lives              : int   = 3
var level              : int   = 1
var hi_score           : int   = 0
var hi_scores          : Array[int] = [0, 0, 0, 0, 0]
var fullscreen         : bool  = false
var scan_strength      : float = 0.30   # 0.0 = off  … 1.0 = max  (maps to scan_dark 0..0.6)
var scan_count_setting : float = 300.0  # 80 = chunky … 600 = fine

const SAVE_PATH     = "user://warkanoid_save.dat"
const SETTINGS_PATH = "user://warkanoid_cfg.dat"

func _ready() -> void:
	_load()
	_load_settings()

func reset() -> void:
	score = 0
	lives = 3
	level = 1

func add_score(pts: int) -> void:
	score += pts
	if score > hi_score:
		hi_score = score

func record_final_score() -> void:
	if score <= 0:
		return
	hi_scores.append(score)
	hi_scores.sort()
	hi_scores.reverse()
	hi_scores.resize(5)
	hi_score = hi_scores[0]
	_save()

func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(800, 600))

func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_8(1 if fullscreen else 0)
		f.store_float(scan_strength)
		f.store_float(scan_count_setting)

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		for s : int in hi_scores:
			f.store_32(s)

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	hi_scores.clear()
	for _i in 5:
		if f.get_position() < f.get_length():
			hi_scores.append(f.get_32())
		else:
			hi_scores.append(0)
	if hi_scores.size() > 0:
		hi_score = hi_scores[0]

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if not f:
		return
	var len : int = f.get_length()
	if len >= 1:
		fullscreen = f.get_8() != 0
	if len >= 5:
		scan_strength = clampf(f.get_float(), 0.0, 1.0)
	if len >= 9:
		scan_count_setting = clampf(f.get_float(), 80.0, 600.0)
	apply_display()
