class_name PetWorld
extends RefCounted
## Offline, single-user prototype. All mutations pass through command().

const Catalog = preload("res://scripts/travel_catalog.gd")
const SAVE_VERSION = 2
const GROW_SECONDS = 18
const TRIP_SECONDS = 35
var data: Dictionary
var save_path: String
var warning = ""

func _init(path: String = "") -> void:
	save_path = path
	data = fresh()
	if not path.is_empty():
		load_save()

func fresh() -> Dictionary:
	return {"schema": SAVE_VERSION, "revision": 0, "name": "苔苔", "herbs": 0, "meals": 0,
		"plots": [0.0, 0.0, 0.0], "trip_end": 0.0, "trip_count": 0, "trip_rain": false,
		"souvenirs": 0, "placed": false, "rain_preference": "unknown", "memory_source": "",
		"letters": [], "events": [], "processed": [], "last_seen": 0.0,
		"active_event": {}, "visited_event_ids": []}

func clock() -> float:
	return maxf(Time.get_unix_time_from_system(), float(data.last_seen))

func advance(now: float) -> bool:
	now = maxf(now, float(data.last_seen))
	data.last_seen = now
	if float(data.trip_end) > 0 and now >= float(data.trip_end):
		data.trip_end = 0.0
		data.trip_count += 1
		data.souvenirs += 1
		var event = data.active_event
		if event.is_empty():
			event = Catalog.choose("creek", [], bool(data.trip_rain))
		data.visited_event_ids.append(event.id)
		if data.visited_event_ids.size() > 120:
			data.visited_event_ids.pop_front()
		data.letters.push_front({"text": event.text, "title": event.title, "destination": event.destination,
			"event_id": event.id, "trip": data.trip_count, "time": now})
		data.active_event = {}
		if data.letters.size() > 30:
			data.letters.resize(30)
		_event("旅行归来，带回一枚青石。", now)
		data.revision += 1
		persist()
		return true
	return false

func command(action: String, payload: Dictionary = {}, now: float = -1.0, key: String = "") -> Dictionary:
	if now < 0:
		now = clock()
	advance(now)
	if not key.is_empty() and key in data.processed:
		return {"ok": false, "message": "这次操作已经处理过啦。", "code": "duplicate"}
	var message = ""
	match action:
		"garden":
			var plot = int(payload.get("plot", -1))
			if plot < 0 or plot >= 3:
				return _fail("找不到这块花圃。")
			var end = float(data.plots[plot])
			if end == 0:
				data.plots[plot] = now + GROW_SECONDS
				message = "种下一株香草，也浇好了水。十八秒后再来看看。"
			elif now >= end:
				data.herbs += 1
				data.plots[plot] = 0.0
				message = "收获了一份香草，刚好可以做便当。"
			else:
				return _fail("正在慢慢长大，不用再浇水啦。")
		"cook":
			if int(data.herbs) < 1:
				return _fail("先去庭院收获一份香草吧。")
			data.herbs -= 1
			data.meals += 1
			message = "香草便当做好了。带上它，就能去溪谷散步。"
		"travel":
			var destination = str(payload.get("destination", "creek"))
			if not Catalog.DESTINATIONS.has(destination):
				return _fail("地图上还没有这个地方。")
			if float(data.trip_end) > 0:
				return _fail("苔苔已经在路上了。")
			if int(data.meals) < 1:
				return _fail("出发前，先准备一份便当。")
			data.meals -= 1
			data.trip_end = now + TRIP_SECONDS
			data.trip_rain = data.rain_preference == "like"
			data.active_event = Catalog.choose(destination, data.visited_event_ids, bool(data.trip_rain))
			if data.active_event.id == "creek_rain" and not bool(data.trip_rain):
				data.active_event.text = "溪边下起了雨。我在大叶子底下躲了一会儿，等天晴才继续走。带回的这枚青石，被雨水洗得亮亮的。"
			message = "苔苔带着便当去%s了。三十五秒后，看看它带回什么。" % Catalog.DESTINATIONS[destination]
		"place":
			if int(data.souvenirs) < 1:
				return _fail("旅行归来后，就有纪念品可以摆放了。")
			if bool(data.placed):
				return _fail("青石已经在窗台上了。")
			data.placed = true
			message = "把青石放在窗台。这里从此多了一段你们的回忆。"
		"remember":
			var preference = str(payload.get("preference", "unknown"))
			if preference not in ["like", "dislike", "unknown"]:
				return _fail("这条记忆还不能保存。")
			data.rain_preference = preference
			data.memory_source = str(payload.get("source", "")) if preference != "unknown" else ""
			message = "偏好已更新。" if preference != "unknown" else "雨声偏好已忘记；历史旅行信仍作为已发生的记录保留。"
		_:
			return _fail("这个动作还不在小屋的规则里。")
	if not key.is_empty():
		data.processed.append(key)
		if data.processed.size() > 100:
			data.processed.pop_front()
	data.revision += 1
	# Preference text is not duplicated into event logs so forgetting clears it.
	_event(message, now)
	persist()
	return {"ok": true, "message": message, "revision": data.revision}

func _fail(message: String) -> Dictionary:
	return {"ok": false, "message": message, "code": "rule_rejected"}

func _event(message: String, now: float) -> void:
	data.events.push_front({"text": message, "time": now})
	if data.events.size() > 40:
		data.events.resize(40)

func persist() -> bool:
	if save_path.is_empty():
		return true
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		warning = "存档写入失败：" + error_string(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, save_path + ".bak")
	var error = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if error != OK:
		warning = "存档替换失败：" + error_string(error)
		return false
	return true

func valid_save(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != SAVE_VERSION:
		return false
	for field in fresh():
		if not value.has(field):
			return false
	for field in ["herbs", "meals", "souvenirs", "trip_count", "revision", "trip_end", "last_seen"]:
		if not (value[field] is float or value[field] is int) or float(value[field]) < 0:
			return false
	if not value.plots is Array or value.plots.size() != 3:
		return false
	for plot in value.plots:
		if not (plot is float or plot is int) or float(plot) < 0:
			return false
	for field in ["letters", "events", "processed"]:
		if not value[field] is Array:
			return false
	for entry in value.letters:
		if not entry is Dictionary or not entry.get("text") is String or not (entry.get("trip") is int or entry.get("trip") is float):
			return false
	for entry in value.events:
		if not entry is Dictionary or not entry.get("text") is String:
			return false
	if not value.visited_event_ids is Array or not value.active_event is Dictionary:
		return false
	if not value.active_event.is_empty() and not Catalog.valid_event(value.active_event):
		return false
	return value.placed is bool and value.trip_rain is bool and value.name is String and value.memory_source is String and value.rain_preference in ["like", "dislike", "unknown"]

func migrate(value: Variant) -> Variant:
	if not value is Dictionary or value.get("schema") != 1:
		return value
	var upgraded = value.duplicate(true)
	upgraded.schema = SAVE_VERSION
	upgraded.active_event = {}
	upgraded.visited_event_ids = []
	if not valid_save(upgraded):
		return null
	if float(upgraded.trip_end) > 0:
		upgraded.active_event = Catalog.choose("creek", [], bool(upgraded.trip_rain))
	return upgraded

func load_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parser = JSON.new()
	var parse_error = parser.parse(FileAccess.get_file_as_string(save_path))
	var original = parser.data if parse_error == OK else null
	var parsed = migrate(original)
	if valid_save(parsed):
		var backup_suffix = ".v%d-backup" % int(original.get("schema", 0))
		if original.get("schema") != parsed.schema and not FileAccess.file_exists(save_path + backup_suffix):
			if DirAccess.copy_absolute(save_path, save_path + backup_suffix) != OK:
				warning = "旧存档备份失败，已暂停写入；请检查磁盘权限。"
				save_path = ""
		data = parsed
		advance(clock())
		return
	# Preserve damaged data before any future save.
	DirAccess.copy_absolute(save_path, save_path + ".corrupt-" + str(Time.get_unix_time_from_system()).replace(".", "-"))
	if FileAccess.file_exists(save_path + ".bak"):
		parse_error = parser.parse(FileAccess.get_file_as_string(save_path + ".bak"))
		parsed = migrate(parser.data if parse_error == OK else null)
		if valid_save(parsed):
			data = parsed
			warning = "主存档异常，已从上一份备份恢复；损坏文件已保留。"
			advance(clock())
			return
	warning = "存档无法读取，原文件已保留；当前使用新的本地生活。"
