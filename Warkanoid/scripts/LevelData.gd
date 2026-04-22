extends Node

const BUILTIN_COUNT : int = 5

func load_level(n: int) -> Dictionary:
	var user_path := "user://levels/level%d.json" % n
	if FileAccess.file_exists(user_path):
		return _parse(user_path)
	var res_path := "res://levels/level%d.json" % n
	var probe := FileAccess.open(res_path, FileAccess.READ)
	if probe != null:
		probe.close()
		return _parse(res_path)
	var eff : int = ((n - 1) % BUILTIN_COUNT) + 1
	return _parse("res://levels/level%d.json" % eff)

func get_level_name(n: int) -> String:
	var data := load_level(n)
	return str(data.get("name", "LEVEL %d" % n))

func save_user_level(n: int, data: Dictionary) -> void:
	DirAccess.make_dir_absolute("user://levels")
	var path := "user://levels/level%d.json" % n
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))

func _parse(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return {}
	var r = JSON.parse_string(f.get_as_text())
	if r is Dictionary:
		return r as Dictionary
	return {}
