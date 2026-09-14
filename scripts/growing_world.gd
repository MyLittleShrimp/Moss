extends "res://scripts/living_world.gd"
## Explicit preferences, observable habits and a dated reading cache.
func fresh() -> Dictionary:
	var value = super.fresh()
	value.schema = 5
	value.merge({"preferences": {}, "memory_epoch": 0, "habits": {"crops": {}, "routes": {}, "reading_days": [], "sweeps": 0}, "daily_book": {}})
	return value

func today(now: float = -1) -> String:
	if now < 0: now = clock()
	return Time.get_date_string_from_unix_time(int(now) + int(Time.get_time_zone_from_system().bias) * 60)

func preference_lines() -> Array:
	var result = []
	for topic in data.preferences:
		result.append(("喜欢" if data.preferences[topic].value == "like" else "不喜欢") + topic)
	return result

func observations() -> Array:
	var result = []
	for id in data.habits.crops:
		result.append("在小屋收获过%s %d次" % [Content.CROPS[id].name, data.habits.crops[id]])
	for id in data.habits.routes:
		result.append("选择去%s旅行 %d次" % [Content.ROUTES[id].name, data.habits.routes[id]])
	if not data.habits.reading_days.is_empty(): result.append("最近读过小书 %d天" % data.habits.reading_days.size())
	return result

func accept_memory_text(text: String) -> Dictionary:
	var topic = ""
	var value = "like"
	for prefix in ["我不喜欢", "我讨厌", "我喜欢", "我爱"]:
		if text.begins_with(prefix):
			topic = text.trim_prefix(prefix).strip_edges().trim_suffix("。").trim_suffix("！")
			value = "dislike" if prefix in ["我不喜欢", "我讨厌"] else "like"
			break
	if topic.is_empty() or topic.length() > 40 or "？" in topic or "?" in topic:
		return {"handled": false}
	var result = command("preference_set", {"topic": topic, "value": value, "source": text.left(100)})
	return {"handled": true, "text": result.message}

func command(action: String, payload: Dictionary = {}, now: float = -1, key: String = "") -> Dictionary:
	if now < 0: now = clock()
	if action == "remember":
		return command("preference_remove" if payload.get("preference", "unknown") == "unknown" else "preference_set", {"topic": "雨声", "value": payload.get("preference", "unknown"), "source": payload.get("source", "")}, now, key)
	if action in ["preference_set", "preference_remove", "clear_observations"]:
		advance(now)
		if not key.is_empty() and key in data.processed: return _fail("这次操作已经处理过啦。")
		var topic = str(payload.get("topic", "")).strip_edges()
		if topic in ["雨", "雨天", "雨声"]: topic = "雨声"
		if action == "preference_set":
			var value = str(payload.get("value", "like"))
			if topic.is_empty() or topic.length() > 40 or value not in ["like", "dislike"]: return _fail("请用40字以内写下一个偏好。")
			if not data.preferences.has(topic) and data.preferences.size() >= 32: return _fail("记忆本暂时放满了32条，请先整理一条旧偏好。")
			data.preferences[topic] = {"value": value, "source": str(payload.get("source", "你在记忆本中填写")).left(100), "updated": now}
			if topic == "雨声":
				data.rain_preference = value
				data.memory_source = data.preferences[topic].source
		elif action == "preference_remove":
			data.preferences.erase(topic)
			if topic == "雨声": data.rain_preference = "unknown"; data.memory_source = ""
		else: data.habits = fresh().habits
		data.memory_epoch += 1
		data.revision += 1
		if not key.is_empty():
			data.processed.append(key)
			if data.processed.size() > 100: data.processed.pop_front()
		persist()
		return {"ok": true, "message": ("记住啦，你" + ("喜欢" if data.preferences[topic].value == "like" else "不喜欢") + topic + "。可以在记忆本里改掉或忘记。") if action == "preference_set" else "当前记忆已清除；已经写下的历史书页和旅行信仍保留。"}
	var was_growing = action == "garden" and int(payload.get("plot", -1)) in [0, 1, 2] and float(data.plots[int(payload.plot)]) > 0
	var crop = str(data.plot_crops[int(payload.plot)]) if was_growing else ""
	var result = super.command(action, payload, now, key)
	if result.ok:
		if action == "garden" and was_growing:
			data.habits.crops[crop] = int(data.habits.crops.get(crop, 0)) + 1
		elif action == "travel":
			var route = str(payload.get("destination", "creek"))
			data.habits.routes[route] = int(data.habits.routes.get(route, 0)) + 1
		elif action == "read_book":
			var day = today(now)
			if day not in data.habits.reading_days:
				data.habits.reading_days.append(day)
				if data.habits.reading_days.size() > 30: data.habits.reading_days.pop_front()
		elif action == "sweep": data.habits.sweeps += 1
		persist()
	return result

func ensure_book(day: String) -> void:
	if data.daily_book.get("day") == day and (data.daily_book.get("source") == "llm" or data.daily_book.get("catalog_version") == 1): return
	var story = preload("res://scripts/yearbook.gd").entry(day)
	var pages = story.pages
	pages[0] = "今日小书 · " + story.title + "\n\n" + pages[0]
	data.daily_book = {"day":day, "source":"local", "catalog_version":1, "attempted":false, "pages":pages}
	data.book_page = 0
	persist()

func begin_book_attempt() -> bool:
	if data.daily_book.is_empty() or data.daily_book.attempted: return false
	data.daily_book.attempted = true
	persist()
	return true

func finish_book(day: String, epoch: int, text: String) -> bool:
	if data.daily_book.get("day") != day or data.memory_epoch != epoch or today() != day or text.is_empty() or text.length() > 240: return false
	# A validated model story is text only. Never execute or interpret it as world commands.
	var pages = []
	var parts = text.strip_edges().split("\n\n", false)
	if parts.size() == 3:
		for part in parts: pages.append(str(part))
	else:
		var width = ceili(text.length() / 3.0)
		for i in range(3): pages.append(text.substr(i * width, width))
	data.daily_book.pages = pages
	data.daily_book.source = "llm"
	persist()
	return true

func migrate(value: Variant) -> Variant:
	if not value is Dictionary: return value
	var result = value
	if value.get("schema") != 4: result = super.migrate(value)
	if not result is Dictionary or result.get("schema") != 4: return result
	result = result.duplicate(true)
	for field in ["preferences", "memory_epoch", "habits", "daily_book"]: result[field] = fresh()[field]
	if result.rain_preference != "unknown": result.preferences["雨声"] = {"value": result.rain_preference, "source": result.memory_source, "updated": result.last_seen}
	result.schema = 5
	return result

func valid_save(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != 5: return false
	var base = value.duplicate(true)
	base.schema = 4
	if not super.valid_save(base): return false
	if not value.preferences is Dictionary or value.preferences.size() > 32 or not natural(value.memory_epoch): return false
	for topic in value.preferences:
		var entry = value.preferences[topic]
		if not topic is String or topic.is_empty() or topic.length() > 40 or not entry is Dictionary: return false
		if entry.get("value") not in ["like", "dislike"] or not entry.get("source") is String or not numeric(entry.get("updated")): return false
	var habits = value.habits
	if not habits is Dictionary or not habits.get("crops") is Dictionary or not habits.get("routes") is Dictionary or not habits.get("reading_days") is Array or not natural(habits.get("sweeps")): return false
	for id in habits.crops:
		if not Content.CROPS.has(id) or not natural(habits.crops[id]): return false
	for id in habits.routes:
		if not Content.ROUTES.has(id) or not natural(habits.routes[id]): return false
	if habits.reading_days.size() > 30: return false
	for day in habits.reading_days:
		if not day is String or day.length() != 10: return false
	var book = value.daily_book
	if not book is Dictionary: return false
	if not book.is_empty():
		if not book.get("day") is String or book.day.length() != 10 or book.get("source") not in ["local", "llm"] or not book.get("attempted") is bool or not book.get("pages") is Array or book.pages.size() != 3: return false
		for page in book.pages:
			if not page is String or page.length() > 300: return false
	return true
