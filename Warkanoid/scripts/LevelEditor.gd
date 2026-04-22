extends Node2D

const SCAN_SHADER = preload("res://shaders/scanlines.gdshader")

const COLS   : int   = 11
const ROWS   : int   = 12
const CELL_W : float = 62.0
const CELL_H : float = 22.0
const GAP_X  : float = 4.0
const GAP_Y  : float = 4.0
const STEP_X : float = CELL_W + GAP_X
const STEP_Y : float = CELL_H + GAP_Y
const GRID_X : float = 37.0
const GRID_Y : float = 76.0

@onready var ui_layer  : CanvasLayer = $UI
@onready var scan_rect : ColorRect   = $Scanlines/ScanRect

var grid          : Array  = []
var selected_val  : int    = 1
var current_level : int    = 1
var is_dragging   : bool   = false
var _game_time    : float  = 0.0
var _scan_mat     : ShaderMaterial
var _status_lbl   : Label
var _level_lbl    : Label
var _hp_btns      : Array  = []

const CELL_COLORS : Array = [
	Color(0.85, 0.25, 0.15),
	Color(0.90, 0.55, 0.08),
	Color(0.75, 0.80, 0.08),
	Color(0.15, 0.45, 0.90),
	Color(0.65, 0.65, 0.65),
]

func _ready() -> void:
	_scan_mat = ShaderMaterial.new()
	_scan_mat.shader = SCAN_SHADER
	_scan_mat.set_shader_parameter("scan_dark",  GameManager.scan_strength * 0.6)
	_scan_mat.set_shader_parameter("scan_count", GameManager.scan_count_setting)
	scan_rect.material = _scan_mat
	$Background.show_behind_parent = true
	_init_grid()
	_build_ui()
	_load_level()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	_game_time += delta
	_scan_mat.set_shader_parameter("time", _game_time)
	queue_redraw()

func _init_grid() -> void:
	grid.clear()
	for _r in ROWS:
		var row : Array = []
		for _c in COLS:
			row.append(0)
		grid.append(row)

func _row(r: int) -> Array:
	return grid[r] as Array

func _build_ui() -> void:
	var toolbar_y : float = GRID_Y + ROWS * STEP_Y + 10.0

	# Title
	var title := Label.new()
	title.text = "LEVEL EDITOR"
	title.set_position(Vector2(20, 10))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.2, 1.0, 0.7))
	ui_layer.add_child(title)

	# Level navigation
	var prev_btn := Button.new()
	prev_btn.text = "<<"
	prev_btn.set_position(Vector2(296, 8))
	prev_btn.set_size(Vector2(38, 28))
	prev_btn.add_theme_font_size_override("font_size", 14)
	prev_btn.pressed.connect(_on_prev_level)
	ui_layer.add_child(prev_btn)

	_level_lbl = Label.new()
	_level_lbl.set_position(Vector2(338, 12))
	_level_lbl.set_size(Vector2(120, 24))
	_level_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_lbl.add_theme_font_size_override("font_size", 15)
	_level_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	ui_layer.add_child(_level_lbl)

	var next_btn := Button.new()
	next_btn.text = ">>"
	next_btn.set_position(Vector2(462, 8))
	next_btn.set_size(Vector2(38, 28))
	next_btn.add_theme_font_size_override("font_size", 14)
	next_btn.pressed.connect(_on_next_level)
	ui_layer.add_child(next_btn)

	# HP selector
	var hp_labels : Array = ["1", "2", "3", "4", "X", "ERASE"]
	var hp_values : Array = [1, 2, 3, 4, 9, 0]
	var hp_colors : Array = CELL_COLORS + [Color(0.45, 0.45, 0.45)]

	var sel_lbl := Label.new()
	sel_lbl.text = "BRICK:"
	sel_lbl.set_position(Vector2(GRID_X, toolbar_y + 6))
	sel_lbl.add_theme_font_size_override("font_size", 12)
	sel_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.65))
	sel_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(sel_lbl)

	_hp_btns.clear()
	for i in hp_labels.size():
		var btn := Button.new()
		btn.text = str(hp_labels[i])
		btn.set_position(Vector2(GRID_X + 58 + i * 52, toolbar_y))
		btn.set_size(Vector2(46, 28))
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", hp_colors[i] as Color)
		btn.toggle_mode = true
		btn.button_pressed = (i == 0)
		btn.pressed.connect(_on_hp_btn.bind(hp_values[i], i))
		ui_layer.add_child(btn)
		_hp_btns.append(btn)

	# Action buttons
	var act_labels : Array = ["CLEAR", "SAVE", "TEST", "BACK"]
	var act_x : float = 452.0
	for i in act_labels.size():
		var abtn := Button.new()
		abtn.text = str(act_labels[i])
		abtn.set_position(Vector2(act_x + i * 88, toolbar_y))
		abtn.set_size(Vector2(80, 28))
		abtn.add_theme_font_size_override("font_size", 13)
		match i:
			0: abtn.pressed.connect(_on_clear)
			1: abtn.pressed.connect(_on_save)
			2: abtn.pressed.connect(_on_test)
			3: abtn.pressed.connect(_on_back)
		ui_layer.add_child(abtn)

	# Status label
	_status_lbl = Label.new()
	_status_lbl.set_position(Vector2(GRID_X, toolbar_y + 34))
	_status_lbl.set_size(Vector2(760, 20))
	_status_lbl.add_theme_font_size_override("font_size", 11)
	_status_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 0.55, 0.85))
	_status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(_status_lbl)

	# Hint
	var hint := Label.new()
	hint.text = "LEFT CLICK = place  ·  RIGHT CLICK = erase  ·  DRAG = paint"
	hint.set_position(Vector2(GRID_X, toolbar_y + 50))
	hint.set_size(Vector2(760, 18))
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.4, 0.6, 0.5, 0.5))
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(hint)

	# ── Transparent click zone over the grid (reliable gui_input) ──
	var grid_zone := ColorRect.new()
	grid_zone.set_position(Vector2(GRID_X, GRID_Y))
	grid_zone.set_size(Vector2(COLS * STEP_X, ROWS * STEP_Y))
	grid_zone.color = Color(0.0, 0.0, 0.0, 0.0)
	grid_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	grid_zone.gui_input.connect(_on_grid_input)
	ui_layer.add_child(grid_zone)

	_update_level_label()

# ── Grid input via CanvasLayer Control ───────────────────────────────────────

func _on_grid_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = mb.pressed
			if mb.pressed:
				_paint_at(mb.position)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_erase_at(mb.position)
	elif event is InputEventMouseMotion and is_dragging:
		_paint_at(event.position)

func _paint_at(local_pos: Vector2) -> void:
	var c : int = int(local_pos.x / STEP_X)
	var r : int = int(local_pos.y / STEP_Y)
	if c >= 0 and c < COLS and r >= 0 and r < ROWS:
		_row(r)[c] = selected_val

func _erase_at(local_pos: Vector2) -> void:
	var c : int = int(local_pos.x / STEP_X)
	var r : int = int(local_pos.y / STEP_Y)
	if c >= 0 and c < COLS and r >= 0 and r < ROWS:
		_row(r)[c] = 0

# ── Level navigation / persistence ──────────────────────────────────────────

func _update_level_label() -> void:
	_level_lbl.text = "LEVEL %d" % current_level

func _on_hp_btn(val: int, idx: int) -> void:
	selected_val = val
	for i in _hp_btns.size():
		(_hp_btns[i] as Button).set_pressed_no_signal(i == idx)

func _on_prev_level() -> void:
	current_level = maxi(1, current_level - 1)
	_update_level_label()
	_load_level()

func _on_next_level() -> void:
	current_level += 1
	_update_level_label()
	_load_level()

func _on_clear() -> void:
	_init_grid()
	_status_lbl.text = "Grid cleared."

func _on_save() -> void:
	var max_row : int = -1
	for r in ROWS:
		for c in COLS:
			if int(_row(r)[c]) != 0:
				max_row = r
	var rows : Array = []
	for r in max_row + 1:
		var s : String = ""
		for c in COLS:
			var v : int = int(_row(r)[c])
			if v == 0:   s += " "
			elif v == 9: s += "X"
			else:        s += str(v)
		rows.append(s.rstrip(" "))
	LevelData.save_user_level(current_level, {"name": "CUSTOM %d" % current_level, "rows": rows})
	_status_lbl.text = "Saved → user://levels/level%d.json" % current_level

func _on_test() -> void:
	_on_save()
	GameManager.reset()
	GameManager.level = current_level
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _load_level() -> void:
	_init_grid()
	var data   := LevelData.load_level(current_level)
	var layout : Array = (data.get("rows", []) as Array)
	for r in mini(layout.size(), ROWS):
		var row_str : String = str(layout[r])
		for c in mini(row_str.length(), COLS):
			var ch : String = row_str[c]
			if   ch == "X" or ch == "x": _row(r)[c] = 9
			elif ch.is_valid_int():       _row(r)[c] = clampi(int(ch), 0, 4)
			else:                         _row(r)[c] = 0
	_status_lbl.text = "Loaded: %s" % LevelData.get_level_name(current_level)

# ── Draw ─────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var gw : float = COLS * STEP_X - GAP_X
	var gh : float = ROWS * STEP_Y - GAP_Y
	draw_rect(Rect2(GRID_X - 4, GRID_Y - 4, gw + 8, gh + 8), Color(0.04, 0.07, 0.14, 0.75))

	for r in ROWS:
		for c in COLS:
			var x : float = GRID_X + c * STEP_X
			var y : float = GRID_Y + r * STEP_Y
			var v : int   = int(_row(r)[c])
			if v == 0:
				draw_rect(Rect2(x, y, CELL_W, CELL_H), Color(0.12, 0.18, 0.28, 0.45), false, 0.5)
			else:
				var col : Color = _cell_color(v)
				draw_rect(Rect2(x, y, CELL_W, CELL_H), col)
				draw_rect(Rect2(x + 2, y + 2, CELL_W - 4, 4), Color(1, 1, 1, 0.22))
				draw_rect(Rect2(x, y, CELL_W, CELL_H), Color(1, 1, 1, 0.5), false, 1.5)

	# Cursor highlight — convert viewport coords to grid-local
	var mp : Vector2 = get_viewport().get_mouse_position() - Vector2(GRID_X, GRID_Y)
	var hc : int = int(mp.x / STEP_X)
	var hr : int = int(mp.y / STEP_Y)
	if mp.x >= 0 and mp.y >= 0 and hc < COLS and hr < ROWS:
		var hx : float = GRID_X + hc * STEP_X
		var hy : float = GRID_Y + hr * STEP_Y
		draw_rect(Rect2(hx - 1, hy - 1, CELL_W + 2, CELL_H + 2), Color(1, 1, 1, 0.4), false, 2.0)

func _cell_color(v: int) -> Color:
	match v:
		1: return Color(0.85, 0.25, 0.15)
		2: return Color(0.90, 0.55, 0.08)
		3: return Color(0.75, 0.80, 0.08)
		4: return Color(0.15, 0.45, 0.90)
		9: return Color(0.60, 0.60, 0.60)
	return Color.WHITE
