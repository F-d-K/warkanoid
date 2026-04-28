extends Node2D

const BALL_SCENE      = preload("res://scenes/Ball.tscn")
const BRICK_SCENE     = preload("res://scenes/Brick.tscn")
const POWERUP_SCENE   = preload("res://scenes/PowerUp.tscn")
const EXPLOSION_SCENE = preload("res://scenes/Explosion.tscn")
const ENEMY_SCENE     = preload("res://scenes/Enemy.tscn")
const PADDLE_SCENE    = preload("res://scenes/Paddle.tscn")
const SCAN_SHADER     = preload("res://shaders/scanlines.gdshader")
const GRID_SHADER     = preload("res://shaders/grid.gdshader")

const BALL_SPEED_BASE : float = 310.0
const WALL_L : float = 14.0
const WALL_R : float = 786.0
const WALL_T : float = 48.0
const SCREEN_BOTTOM : float = 620.0

# Each player's paddle is confined to its half of the screen
const P1_MIN_X : float = 59.0    # WALL_L + HALF_W
const P1_MAX_X : float = 420.0
const P2_MIN_X : float = 380.0
const P2_MAX_X : float = 741.0   # WALL_R - HALF_W

@onready var paddle       = $Paddle
@onready var background   = $Background
@onready var bricks_layer = $BricksLayer
@onready var score_lbl  : Label     = $HUD/ScoreLabel
@onready var lives_lbl  : Label     = $HUD/LivesLabel
@onready var level_lbl  : Label     = $HUD/LevelLabel
@onready var hi_lbl     : Label     = $HUD/HiLabel
@onready var msg_lbl    : Label     = $HUD/MsgLabel
@onready var pw_lbl     : Label     = $HUD/PowerupLabel
@onready var scan_rect  : ColorRect = $Scanlines/ScanRect

var paddle2           = null
var _score_p2_lbl     : Label = null

var balls      : Array = []
var bricks     : Array = []
var powerups   : Array = []
var enemies    : Array = []

const ENEMY_MAX           : int   = 3
const ENEMY_SPAWN_FIRST   : float = 6.0
var   _enemy_timer        : float = ENEMY_SPAWN_FIRST

var _shake_time : float = 0.0
var _shake_mag  : float = 0.0
var _base_pos   : Vector2 = Vector2.ZERO
var _game_time  : float = 0.0
var _scan_mat    : ShaderMaterial
var _grid_mat    : ShaderMaterial
var _grid_pulse  : float = 0.0
var _mouse_was_pressed : bool = false

# Tracks who last touched the ball that hit a brick/enemy
var _last_brick_hitter : int = 1

# Powerup state
var _pw_timer   : float = 0.0
var _pw_type    : int   = -1
const PW_DUR    : float = 8.0
const PW_WIDE   : int   = 0
const PW_MULTI  : int   = 1
const PW_FIRE   : int   = 2
const PW_SLOW   : int   = 3

var _paddle_wide : bool = false

var _state : String = "waiting"   # waiting | playing | dead | levelup | gameover

func _ready() -> void:
	_base_pos = position

	_scan_mat = ShaderMaterial.new()
	_scan_mat.shader = SCAN_SHADER
	_scan_mat.set_shader_parameter("scan_dark",  GameManager.scan_strength * 0.6)
	_scan_mat.set_shader_parameter("scan_count", GameManager.scan_count_setting)
	scan_rect.material = _scan_mat

	# Animated grid background
	for ch in background.get_children():
		ch.queue_free()
	_grid_mat = ShaderMaterial.new()
	_grid_mat.shader = GRID_SHADER
	var grid_rect := ColorRect.new()
	grid_rect.size = Vector2(800, 600)
	grid_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid_rect.material = _grid_mat
	background.add_child(grid_rect)

	# P1 paddle: left zone, mouse-driven
	paddle.player_id = 1
	paddle.min_x     = P1_MIN_X
	paddle.max_x     = P1_MAX_X

	# P2 paddle: right zone, keyboard/gamepad-driven
	paddle2 = PADDLE_SCENE.instantiate()
	paddle2.player_id = 2
	paddle2.min_x     = P2_MIN_X
	paddle2.max_x     = P2_MAX_X
	paddle2.position  = Vector2(600.0, paddle.position.y)
	add_child(paddle2)

	# P2 score label added dynamically to the HUD CanvasLayer
	_score_p2_lbl = Label.new()
	_score_p2_lbl.add_theme_color_override("font_color", Color.from_hsv(0.55, 0.9, 1.0))
	_score_p2_lbl.position = score_lbl.position + Vector2(0, 24)
	$HUD.add_child(_score_p2_lbl)

	GameManager.reset()
	_spawn_level()
	_set_state("waiting")

func _process(delta: float) -> void:
	_game_time += delta
	_scan_mat.set_shader_parameter("time", _game_time)
	_grid_pulse = lerpf(_grid_pulse, 0.0, delta * 4.0)
	_grid_mat.set_shader_parameter("pulse", _grid_pulse)
	_grid_mat.set_shader_parameter("time",  _game_time)
	_tick_shake(delta)
	_tick_powerup(delta)

	var mouse_now := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var mouse_clicked := mouse_now and not _mouse_was_pressed
	_mouse_was_pressed = mouse_now

	match _state:
		"waiting":
			# Waiting balls follow their respective paddles
			if balls.size() > 0 and is_instance_valid(balls[0]):
				balls[0].position = paddle.position + Vector2(0, -28)
			if balls.size() > 1 and is_instance_valid(balls[1]):
				balls[1].position = paddle2.position + Vector2(0, -28)
			if mouse_clicked or Input.is_action_just_pressed("ui_accept"):
				_launch_balls()
		"playing":
			_move_balls(delta)
			_check_powerup_pickup()
			_tick_enemies(delta)
			_update_powerup_label()
		"dead", "levelup", "gameover":
			pass

	_update_hud()

# ── State ────────────────────────────────────────────────────────────────────

func _set_state(s: String) -> void:
	_state = s
	match s:
		"waiting":
			var lname : String = LevelData.get_level_name(GameManager.level)
			msg_lbl.text = lname + "  ·  P1:CLICK   P2:←→"
			msg_lbl.add_theme_color_override("font_color", Color(1, 1, 0.4))
		"playing":
			msg_lbl.text = ""
		"dead":
			msg_lbl.text = "BALL LOST!"
			msg_lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			background.on_die()
			SoundManager.play_die()
			get_tree().create_timer(1.4).timeout.connect(_after_death)
		"levelup":
			msg_lbl.text = "LEVEL UP!"
			msg_lbl.add_theme_color_override("font_color", Color(0.3, 1, 0.5))
			background.on_level_up()
			SoundManager.play_level_up()
			get_tree().create_timer(1.8).timeout.connect(_next_level)
		"gameover":
			msg_lbl.text = "GAME OVER"
			msg_lbl.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
			background.on_die()
			SoundManager.play_die()
			get_tree().create_timer(2.5).timeout.connect(_go_menu)

func _after_death() -> void:
	if GameManager.lives <= 0:
		_set_state("gameover")
	else:
		_clear_balls()
		_clear_powerups()
		_clear_enemies()
		_cancel_powerup()
		_spawn_balls()
		_set_state("waiting")

func _next_level() -> void:
	GameManager.level += 1
	_clear_balls()
	_clear_powerups()
	_clear_enemies()
	_cancel_powerup()
	_spawn_level()
	_set_state("waiting")

func _input(_event: InputEvent) -> void:
	pass

func _go_menu() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

# ── Level spawning ────────────────────────────────────────────────────────────

func _spawn_level() -> void:
	for ch in bricks_layer.get_children():
		ch.queue_free()
	bricks.clear()

	var data   := LevelData.load_level(GameManager.level)
	var layout : Array = (data.get("rows", []) as Array)
	var start_x : float = 40.0
	var start_y : float = 70.0
	var bw : float = 62.0
	var bh : float = 26.0
	var gap_x : float = 4.0
	var gap_y : float = 4.0

	for row_idx in layout.size():
		var row : String = str(layout[row_idx])
		for grid_col in row.length():
			var ch : String = row[grid_col]
			if ch == " ": continue
			var hp_val : int = 1
			var indestr : bool = false
			if ch == "X":
				indestr = true
			elif ch.is_valid_int():
				hp_val = clampi(int(ch), 1, 4)

			var br = BRICK_SCENE.instantiate()
			br.hp      = 99 if indestr else hp_val
			br.max_hp  = br.hp
			br.points  = hp_val * 10 * GameManager.level
			br.col_idx = (hp_val - 1) % 6
			br.position = Vector2(
				start_x + grid_col * (bw + gap_x),
				start_y + row_idx * (bh + gap_y)
			)
			br.connect("destroyed", _on_brick_destroyed)
			bricks_layer.add_child(br)
			bricks.append(br)
			br.queue_redraw()

	_spawn_balls()

func _spawn_balls() -> void:
	var b1 = BALL_SCENE.instantiate()
	b1.position    = paddle.position + Vector2(0, -28)
	b1.last_player = 1
	add_child(b1)
	balls.append(b1)

	var b2 = BALL_SCENE.instantiate()
	b2.position    = paddle2.position + Vector2(0, -28)
	b2.last_player = 2
	add_child(b2)
	balls.append(b2)

func _launch_balls() -> void:
	SoundManager.play_launch()
	_set_state("playing")
	for b in balls:
		if is_instance_valid(b) and not b.active:
			var angle := randf_range(deg_to_rad(-60), deg_to_rad(-120))
			var spd   := _ball_speed()
			b.velocity = Vector2(cos(angle), sin(angle)) * spd
			b.active   = true

func _ball_speed() -> float:
	var s := BALL_SPEED_BASE + (GameManager.level - 1) * 20.0
	if _pw_type == PW_SLOW: s *= 0.6
	return s

# ── Ball physics ─────────────────────────────────────────────────────────────

func _move_balls(delta: float) -> void:
	var to_remove : Array = []
	for ball in balls:
		if not is_instance_valid(ball) or ball.is_queued_for_deletion():
			to_remove.append(ball)
			continue
		_step_ball(ball, delta)
		if ball.position.y > SCREEN_BOTTOM:
			to_remove.append(ball)
			ball.queue_free()

	for b in to_remove:
		balls.erase(b)

	if balls.is_empty() and _state == "playing":
		GameManager.lives -= 1
		_set_state("dead")

func _step_ball(ball, delta: float) -> void:
	ball.position += ball.velocity * delta

	# Wall bounces
	if ball.position.x - 7 < WALL_L:
		ball.position.x = WALL_L + 7
		ball.velocity.x = absf(ball.velocity.x)
		_on_bounce(ball.position)
	if ball.position.x + 7 > WALL_R:
		ball.position.x = WALL_R - 7
		ball.velocity.x = -absf(ball.velocity.x)
		_on_bounce(ball.position)
	if ball.position.y - 7 < WALL_T:
		ball.position.y = WALL_T + 7
		ball.velocity.y = absf(ball.velocity.y)
		_on_bounce(ball.position)

	# Paddle 1 collision
	var pr1  : Rect2   = paddle.rect as Rect2
	var bvel : Vector2 = ball.velocity as Vector2
	var bpos : Vector2 = ball.position as Vector2
	if bvel.y > 0 and \
	   bpos.x + 7 > pr1.position.x and bpos.x - 7 < pr1.position.x + pr1.size.x and \
	   bpos.y + 7 >= pr1.position.y - 4 and bpos.y - 7 <= pr1.position.y + pr1.size.y:
		var rel      : float = (bpos.x - (pr1.position.x + pr1.size.x * 0.5)) / (pr1.size.x * 0.5)
		rel = clamp(rel, -0.9, 0.9)
		var outangle : float = rel * deg_to_rad(65)
		var spd      : float = bvel.length()
		ball.velocity        = Vector2(sin(outangle), -abs(cos(outangle))) * spd
		ball.position.y      = pr1.position.y - 7
		ball.last_player     = 1
		_on_bounce(ball.position as Vector2)
		paddle.flash()

	# Paddle 2 collision
	var pr2 : Rect2 = paddle2.rect as Rect2
	bvel = ball.velocity as Vector2
	bpos = ball.position as Vector2
	if bvel.y > 0 and \
	   bpos.x + 7 > pr2.position.x and bpos.x - 7 < pr2.position.x + pr2.size.x and \
	   bpos.y + 7 >= pr2.position.y - 4 and bpos.y - 7 <= pr2.position.y + pr2.size.y:
		var rel      : float = (bpos.x - (pr2.position.x + pr2.size.x * 0.5)) / (pr2.size.x * 0.5)
		rel = clamp(rel, -0.9, 0.9)
		var outangle : float = rel * deg_to_rad(65)
		var spd      : float = bvel.length()
		ball.velocity        = Vector2(sin(outangle), -abs(cos(outangle))) * spd
		ball.position.y      = pr2.position.y - 7
		ball.last_player     = 2
		_on_bounce(ball.position as Vector2)
		paddle2.flash()

	_check_ball_bricks(ball)
	_check_ball_enemies(ball)

func _check_ball_bricks(ball) -> void:
	for br in bricks:
		if not is_instance_valid(br) or br.is_queued_for_deletion():
			continue
		var hw   : float   = 28.0
		var hh   : float   = 11.0
		var brp  : Vector2 = (br as Node2D).position
		var bx   : float   = brp.x
		var by   : float   = brp.y
		var bx1  : float   = bx - hw
		var bx2  : float   = bx + hw
		var by1  : float   = by - hh
		var by2  : float   = by + hh
		var bpos : Vector2 = ball.position as Vector2
		var brad : float   = 7.0

		if bpos.x + brad < bx1 or bpos.x - brad > bx2: continue
		if bpos.y + brad < by1 or bpos.y - brad > by2: continue

		var overlap_x : float = minf(bpos.x + brad - bx1, bx2 - (bpos.x - brad))
		var overlap_y : float = minf(bpos.y + brad - by1, by2 - (bpos.y - brad))

		if _pw_type != PW_FIRE:
			var vel : Vector2 = ball.velocity as Vector2
			if overlap_x < overlap_y:
				vel.x *= -1
				ball.position.x = bx1 - brad if bpos.x < bx else bx2 + brad
			else:
				vel.y *= -1
				ball.position.y = by1 - brad if bpos.y < by else by2 + brad
			ball.velocity = vel

		var spd : float = _ball_speed()
		var v   : Vector2 = ball.velocity as Vector2
		if v.length() > 0:
			ball.velocity = v.normalized() * spd

		if br.hp < 99:
			_last_brick_hitter = ball.last_player
			br.hit()
		else:
			br._flash = 0.4
		break

func _tick_enemies(delta: float) -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	_enemy_timer -= delta
	if _enemy_timer <= 0.0 and enemies.size() < ENEMY_MAX:
		_spawn_enemy()
		_enemy_timer = randf_range(8.0, 14.0)

func _spawn_enemy() -> void:
	var e = ENEMY_SCENE.instantiate()
	e.position = Vector2(randf_range(80.0, 720.0), randf_range(90.0, 420.0))
	add_child(e)
	enemies.append(e)

func _check_ball_enemies(ball) -> void:
	var brad : float = 7.0
	var erad : float = 11.0
	for e in enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			continue
		var bpos  : Vector2 = ball.position as Vector2
		var epos  : Vector2 = (e as Node2D).position
		var diff  : Vector2 = bpos - epos
		if diff.length() >= brad + erad:
			continue
		var normal : Vector2 = diff.normalized() if diff.length() > 0.001 else Vector2.UP
		ball.velocity = (ball.velocity as Vector2).bounce(normal)
		ball.position = epos + normal * (brad + erad + 1.0)
		(e as Node2D).set("_flash", 1.0)
		e.queue_free()
		enemies.erase(e)
		GameManager.add_score_for(25 * GameManager.level, ball.last_player)
		_on_bounce(bpos)
		break

func _clear_enemies() -> void:
	for e in enemies:
		if is_instance_valid(e): e.queue_free()
	enemies.clear()
	_enemy_timer = ENEMY_SPAWN_FIRST

func _on_bounce(pos: Vector2) -> void:
	SoundManager.play_bounce()
	background.on_bounce(pos)
	_grid_pulse = minf(_grid_pulse + 0.6, 2.0)
	_grid_mat.set_shader_parameter("pulse", _grid_pulse)
	_add_shake(0.8)

# ── Brick destroyed ──────────────────────────────────────────────────────────

func _on_brick_destroyed(pos: Vector2, pts: int) -> void:
	GameManager.add_score_for(pts, _last_brick_hitter)
	bricks = bricks.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion())

	var exp = EXPLOSION_SCENE.instantiate()
	exp.position = pos
	exp.col = Color.from_hsv(randf(), 0.9, 1.0)
	add_child(exp)

	SoundManager.play_brick()
	background.on_brick(pos)
	_add_shake(2.0)

	if randf() < 0.20:
		var pu = POWERUP_SCENE.instantiate()
		pu.position = pos
		pu.ptype    = randi() % 4
		add_child(pu)
		powerups.append(pu)

	var alive := bricks.filter(func(b): return is_instance_valid(b) and not b.is_queued_for_deletion() and b.hp > 0 and b.hp < 99)
	if alive.is_empty():
		_set_state("levelup")

# ── Powerup pickup ───────────────────────────────────────────────────────────

func _check_powerup_pickup() -> void:
	var pr1 : Rect2 = paddle.rect  as Rect2
	var pr2 : Rect2 = paddle2.rect as Rect2
	var keep : Array = []
	for pu in powerups:
		if not is_instance_valid(pu) or pu.is_queued_for_deletion():
			continue
		var pp : Vector2 = pu.position
		var caught : bool = false
		for pr in [pr1, pr2]:
			if pp.y > pr.position.y and pp.y < pr.position.y + pr.size.y and \
			   pp.x > pr.position.x and pp.x < pr.position.x + pr.size.x:
				_apply_powerup(pu.ptype)
				pu.queue_free()
				caught = true
				break
		if not caught:
			keep.append(pu)
	powerups = keep

func _apply_powerup(t: int) -> void:
	_pw_type  = t
	_pw_timer = PW_DUR
	SoundManager.play_powerup()
	background.on_powerup()
	_add_shake(3.0)

	match t:
		PW_WIDE:
			paddle.scale.x  = 1.5
			paddle2.scale.x = 1.5
		PW_MULTI:
			var src_balls := balls.duplicate()
			for sb in src_balls:
				if not is_instance_valid(sb): continue
				for _i in 2:
					var nb = BALL_SCENE.instantiate()
					nb.position    = sb.position
					nb.last_player = sb.last_player
					var spd := _ball_speed()
					var a   := randf_range(deg_to_rad(-150), deg_to_rad(-30))
					nb.velocity = Vector2(cos(a), sin(a)) * spd
					nb.active   = true
					add_child(nb)
					balls.append(nb)

func _tick_powerup(delta: float) -> void:
	if _pw_type == -1: return
	_pw_timer -= delta
	if _pw_timer <= 0.0:
		_cancel_powerup()

func _cancel_powerup() -> void:
	if _pw_type == PW_WIDE:
		paddle.scale.x  = 1.0
		paddle2.scale.x = 1.0
	_pw_type  = -1
	_pw_timer = 0.0

func _update_powerup_label() -> void:
	if _pw_type == -1:
		pw_lbl.text = ""
		return
	var names : Array[String] = ["WIDE PADDLE", "MULTI BALL", "FIREBALL", "SLOW BALL"]
	var hues  : Array[float]  = [0.33, 0.58, 0.02, 0.55]
	var t : float = snappedf(_pw_timer, 0.1)
	var h : float = hues[_pw_type % hues.size()]
	pw_lbl.text = "%s  %.1fs" % [names[_pw_type], t]
	pw_lbl.add_theme_color_override("font_color", Color.from_hsv(h, 0.9, 1.0))

# ── Screen shake ─────────────────────────────────────────────────────────────

func _add_shake(mag: float) -> void:
	_shake_mag  = minf(_shake_mag + mag, 8.0)
	_shake_time = 0.25

func _tick_shake(delta: float) -> void:
	_shake_time = maxf(0.0, _shake_time - delta)
	if _shake_time > 0.0 and _shake_mag > 0.0:
		var t := _shake_time / 0.25
		var ox := randf_range(-1.0, 1.0) * _shake_mag * t
		var oy := randf_range(-1.0, 1.0) * _shake_mag * t
		position = _base_pos + Vector2(ox, oy)
		_shake_mag = lerpf(_shake_mag, 0.0, delta * 8.0)
	else:
		position = _base_pos

# ── HUD ──────────────────────────────────────────────────────────────────────

func _update_hud() -> void:
	score_lbl.text  = "P1  %d"    % GameManager.score_p1
	if _score_p2_lbl:
		_score_p2_lbl.text = "P2  %d" % GameManager.score_p2
	lives_lbl.text  = "LIVES  %d"  % GameManager.lives
	level_lbl.text  = "LEVEL  %d"  % GameManager.level
	hi_lbl.text     = "BEST  %d"   % GameManager.hi_score

# ── Cleanup helpers ──────────────────────────────────────────────────────────

func _clear_balls() -> void:
	for b in balls:
		if is_instance_valid(b): b.queue_free()
	balls.clear()

func _clear_powerups() -> void:
	for p in powerups:
		if is_instance_valid(p): p.queue_free()
	powerups.clear()
