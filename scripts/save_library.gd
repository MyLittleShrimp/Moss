extends RefCounted
const World = preload("res://scripts/discovery_world.gd")
const Profile = preload("res://scripts/build_profile.gd")
var directory: String
var active = ""
var error = ""

func _init(path: String = "") -> void:
	if path == "memory://": directory = ""; return
	directory = path if not path.is_empty() else "user://saves/" + Profile.channel()
	DirAccess.make_dir_recursive_absolute(directory)
	var config = ConfigFile.new()
	if config.load(directory + "/active.cfg") == OK: active = str(config.get_value("save", "id", ""))
	if not valid_id(active): active = ""

func valid_id(id: String) -> bool:
	return not id.is_empty() and id.length() < 100 and id.is_valid_filename() and not "." in id and not "/" in id and not "\\" in id

func path_for(id: String) -> String:
	return directory + "/" + id + ".json"

func select(id: String) -> bool:
	if not valid_id(id): return false
	var config = ConfigFile.new()
	config.set_value("save", "id", id)
	if config.save(directory + "/active.cfg") != OK:
		error = "无法保存存档选择。"
		return false
	active = id
	return true

func decoded(path: String):
	if not FileAccess.file_exists(path): error = "存档不存在。"; return null
	if FileAccess.get_file_as_bytes(path).size() > 4 * 1024 * 1024: error = "文件过大，无法作为小屋存档读取。"; return null
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: error = "JSON 损坏，原文件没有改动。"; return null
	var probe = World.new()
	var value = parser.data
	# Export envelopes contain game state only; never AI configuration.
	if value is Dictionary and value.get("format") == "moss-portable-save": value = value.get("state")
	value = probe.migrate(value)
	if not probe.valid_save(value): error = "存档版本或内容不受支持，原文件没有改动。"; return null
	return value

func slots() -> Array:
	var result = []
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".json"):
			var id = file.trim_suffix(".json")
			if valid_id(id):
				var value = decoded(path_for(id))
				result.append({"id": id, "title": str(value.get("slot_title", "苔苔的小屋")) if value is Dictionary else "损坏存档（可保留排查）"})
	return result

func create(title: String, state = null):
	var world = World.new()
	if state != null:
		if not world.valid_save(state): error = "不能复制无效存档。"; return null
		world.data = state.duplicate(true)
	world.data.slot_title = title.strip_edges().left(40) if not title.strip_edges().is_empty() else "苔苔的小屋"
	var id = "slot_" + str(Time.get_ticks_usec()) + "_" + str(randi())
	world.save_path = path_for(id)
	if not world.persist(): error = world.warning; return null
	if not select(id): return null
	world.release_timing = Profile.release_build()
	return world

func load_slot(id: String):
	if not valid_id(id): error = "无效存档编号。"; return null
	var state = decoded(path_for(id))
	if state == null: return null
	# Standard loader preserves migration backups and settles elapsed time.
	var world = World.new(path_for(id))
	world.release_timing = Profile.release_build()
	if world.save_path.is_empty(): error = world.warning; return null
	if not select(id): return null
	return world

func initial(legacy: String = "user://moss_save.json"):
	if not active.is_empty():
		var loaded = load_slot(active)
		if loaded != null: return loaded
		# Never silently replace a damaged active slot.
		var fallback = World.new()
		fallback.warning = error + " 当前为临时生活；请打开设置导入或选择其他存档。"
		return fallback
	if not Profile.release_build() and FileAccess.file_exists(legacy):
		var state = decoded(legacy)
		if state != null: return create("旧小屋 · 已迁入", state)
		var fallback = World.new()
		fallback.warning = error + " 旧存档已保留，请在设置中处理。"
		return fallback
	return create("我的小屋")

func import_save(path: String, title: String):
	var state = decoded(path)
	if state == null: return null
	return create(title, state)

func export_save(world, path: String) -> bool:
	# Exports are new files only; overwrite is deliberately avoided.
	if FileAccess.file_exists(path): error = "文件已存在，请换一个名称。"; return false
	if not world.valid_save(world.data): error = "当前存档无效，无法导出。"; return false
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: error = "导出失败，请检查文件夹权限。"; return false
	file.store_string(JSON.stringify({"format": "moss-portable-save", "version": 1, "state": world.data}, "\t"))
	file.close()
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: error = "导出文件替换失败。"; return false
	return true
