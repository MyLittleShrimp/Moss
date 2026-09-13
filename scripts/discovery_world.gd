extends "res://scripts/reward_world.gd"
const Mail = preload("res://scripts/travel_mail.gd")
var mail_arrivals = 0
## Discovery is persisted with settlement; opening a parcel never grants loot twice.
func fresh() -> Dictionary:
	var value = super.fresh()
	value.schema = 7
	value.travel_progress = {}
	value.pending_discoveries = []
	value.rare_misses = {}
	for id in Content.ROUTES: value.rare_misses[id] = 0
	return value

func discovered(item: String) -> bool:
	return item in data.collected and item not in data.pending_discoveries

func outfit_unlocked(id: String) -> bool:
	return super.outfit_unlocked(id) and (id == "plain" or discovered(OUTFITS[id].item))

func give(item: String) -> void:
	var first = item not in data.collected
	super.give(item)
	if first: data.pending_discoveries.append(item)

func rare_chance(destination: String, snack: bool = false) -> float:
	var misses = int(data.rare_misses[destination])
	var chance = minf(1.0, float(Content.ROUTES[destination].chance) + maxf(0, misses - 2) * 0.12)
	if balanced_timing() and destination in Content.LONG_ROUTES: chance = minf(1.0, float(Content.ROUTES[destination].chance) + misses * 0.25)
	return minf(1.0, chance + (0.15 if snack else 0.0))

func roll_rare(destination: String, snack: bool = false) -> String:
	return Content.ROUTES[destination].rare if int(data.rare_misses[destination]) >= rare_guarantee(destination) - 1 or rng.randf() < rare_chance(destination, snack) else ""

func rare_guarantee(destination: String) -> int:
	return {"tokyo": 5, "istanbul": 4, "paris": 3, "iceland": 3}.get(destination, 8) if balanced_timing() else 8

func advance(now: float) -> bool:
	now = maxf(now, float(data.last_seen))
	if not data.has("travel_progress"): data.travel_progress = {}
	var schedule_needed = float(data.trip_end) > 0 and data.trip_snapshot.get("mail_route_version") != 3
	var delivered = Mail.deliver(self, now)
	mail_arrivals += delivered
	if float(data.trip_end) > 0 and maxf(now, data.last_seen) >= float(data.trip_end) and data.trip_snapshot.get("incident") != "forgot":
		var destination = str(data.active_event.destination)
		data.rare_misses[destination] = 0 if data.trip_snapshot.get("rare", "") != "" else mini(7, int(data.rare_misses[destination]) + 1)
	# Stage permanent progress before parent settlement persists, exactly once per arrival.
	var progress_note = ""
	if float(data.trip_end) > 0 and now >= float(data.trip_end) and data.trip_snapshot.get("incident") != "forgot":
		var actual = str(data.active_event.destination)
		var destination = str(data.trip_snapshot.get("planned", actual))
		if destination in Content.LONG_ROUTES:
			data.travel_progress[destination] = int(data.travel_progress.get(destination, 0)) + 1
			var pages = int(data.travel_progress[destination])
			var coins = Content.PROGRESS_COINS[destination] + (6 if pages % 3 == 0 else 0)
			data.coins += coins
			progress_note = "旅册新进展 · %s 第 %d 页 · 叶币 +%d%s" % [Content.ROUTES[destination].name, pages, coins, " · 新一册纪念章完成" if pages % 3 == 0 else ""]
			var chapter = progress_story(destination, pages)
			if actual != destination: chapter = "改道小记：原本计划去" + Content.ROUTES[destination].name + "，这次跟朋友去了" + Content.ROUTES[actual].name + "。在旅册里画一条弯弯的线，记住这次意外的相聚；原定的远方留给下一次。"
			data.active_event.text += "\n\n" + chapter + "\n本次行程实际到访：" + Content.ROUTES[actual].name + "。\n" + progress_note
	var returned = super.advance(now)
	if delivered > 0 or schedule_needed: persist()
	return returned

func progress_story(destination: String, pages: int) -> String:
	var chapters = {
		"tokyo": ["把樱花树下的电车站画在旅册第一页，约好下次沿另一条街散步。", "街角的小店主人认出了我的围巾，在地图上圈出一处安静的庭院。", "夜色中的灯光拼成小小的星图。我把三段散步的记忆装订在一起。"],
		"istanbul": ["在渡轮上画下海峡两岸的轮廓，第一次听清这座城市的风声。", "陶器店的老人教我辨认蓝色花纹。我在旅册边缘练习了好多遍。", "把渡轮票根与蓝色速写收在一起，这一册终于有了海风的颜色。"],
		"paris": ["从面包店出发，画下一条沿着河岸走的小路。", "再次经过河边时，遇见正在写生的人，我们交换了各自喜欢的颜色。", "收好三张街角速写，在封面画一朵小花，完成属于我的巴黎小册。"],
		"iceland": ["记下港口第一盏亮起的窗灯，给漫长的极光等待留一个温暖的开头。", "沿着黑色海岸散步，学着把风的方向画成弯弯的线。", "把窗灯、海风与夜空的颜色装订成册。远方终于在纸上变成了一个家。"]}
	var moments = chapters[destination]
	return "%s · 第 %d 册，手记 %d：%s" % [Content.ROUTES[destination].name, ceili(pages / 3.0), (pages - 1) % 3 + 1, moments[(pages - 1) % 3]]

func command(action: String, payload: Dictionary = {}, now: float = -1, key: String = "") -> Dictionary:
	if now < 0: now = clock()
	if action == "read_mail":
		for entry in data.get("travel_mail", []):
			if entry.id == payload.get("id"):
				entry.read = true
				persist()
				return {"ok": true, "message": "已收好这封途中来信。"}
		return _fail("这封信还没有寄到。")
	if action == "reveal_next":
		advance(now)
		if not key.is_empty() and key in data.processed: return _fail("这份包裹已经拆过啦。")
		if data.pending_discoveries.is_empty(): return _fail("包裹都收好了。")
		var item = data.pending_discoveries.pop_front()
		if not key.is_empty():
			data.processed.append(key)
			if data.processed.size() > 100: data.processed.pop_front()
		data.revision += 1
		_event("打开旅行包裹，发现了" + Content.ITEMS[item].name + "。", now)
		persist()
		return {"ok": true, "item": item, "message": "新发现 · " + Content.ITEMS[item].name}
	if action in ["claim_room_reward", "sell"] and not discovered(str(payload.get("item", ""))): return _fail("先打开旅行包裹，看看带回了什么吧。")
	if action == "place" and not discovered("stone"): return _fail("先看看旅行带回的包裹吧。")
	return super.command(action, payload, now, key)

func persist() -> bool:
	Mail.prepare(self, float(data.last_seen))
	# Do not spoil unopened discoveries through the journal or care history.
	if data.has("pending_discoveries"):
		for item in data.pending_discoveries:
			var names = [Content.ITEMS[item].name]
			for outfit in OUTFITS.values():
				if outfit.item == item: names.append(outfit.name)
			if ROOM_REWARDS.has(item): names.append(ROOM_REWARDS[item].name)
			for name in names:
				for letter in data.letters:
					if letter.has("rewards"): letter.rewards = str(letter.rewards).replace(name, "未拆的旅行礼物")
				for event in data.events: event.text = str(event.text).replace(name, "未拆的旅行礼物")
	return super.persist()

func migrate(value: Variant) -> Variant:
	if not value is Dictionary: return value
	var original_schema = value.get("schema", 0)
	var result = value if original_schema == 6 else super.migrate(value)
	if not result is Dictionary or result.get("schema") != 6: return result
	result = result.duplicate(true)
	if not result.get("ingredients") is Dictionary or not result.get("foods") is Dictionary: return null
	# Only new catalog entries are added; missing old entries remain a corrupt-save error.
	for id in ["corn", "carrot", "potato", "strawberry"]: result.ingredients[id] = 0
	for id in ["corn_ball", "veggie_box", "potato_box", "berry_snack"]: result.foods[id] = 0
	result.pending_discoveries = []
	result.rare_misses = fresh().rare_misses
	result.schema = 7
	return result

func valid_save(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != 7: return false
	var base = value.duplicate(true)
	base.schema = 6
	if not base.has("travel_progress"): base.travel_progress = {}
	if not super.valid_save(base): return false
	if not value.pending_discoveries is Array or value.pending_discoveries.size() > Content.ITEMS.size() or not value.rare_misses is Dictionary: return false
	var seen = []
	for item in value.pending_discoveries:
		if item not in value.collected or item in seen: return false
		seen.append(item)
	for id in Content.ROUTES:
		if not natural(value.rare_misses.get(id)) or value.rare_misses[id] > 7: return false
	if value.trip_snapshot.has("snack") and not value.trip_snapshot.snack is bool: return false
	var progress = value.get("travel_progress", {})
	if not progress is Dictionary: return false
	for id in progress:
		if id not in Content.LONG_ROUTES or not natural(progress[id]) or progress[id] > 100000000: return false
	if value.trip_snapshot.has("mail_gap") and (not numeric(value.trip_snapshot.mail_gap) or value.trip_snapshot.mail_gap < 1 or value.trip_snapshot.mail_gap > 172800): return false
	var archive = value.get("travel_mail", [])
	var schedule = value.trip_snapshot.get("mail_schedule", [])
	if not archive is Array or archive.size() > 60 or not schedule is Array or schedule.size() > 24: return false
	var ids = []
	for entry in archive + schedule:
		if not Mail.valid(entry, self) or entry.id in ids: return false
		ids.append(entry.id)
	var previous = -1.0
	var cities = []
	if value.trip_snapshot.get("mail_route_version") in [2, 3]:
		var itinerary = value.trip_snapshot.get("mail_route")
		if not itinerary is Array: return false
		var destination = value.active_event.get("destination", "")
		var expected = Mail.ROUTES.get(destination, [])
		if destination == "iceland":
			if itinerary not in [["shanghai", "dubai", "london", "stockholm"], ["shanghai", "dubai", "london", "copenhagen"]] and value.trip_snapshot.get("incident") != "forgot": return false
		elif itinerary != expected and value.trip_snapshot.get("incident") != "forgot": return false
		var index = -1
		for entry in schedule:
			if entry.get("reassurance", false):
				if entry.kind != "letter" or entry.destination != destination or int(entry.trip) != int(value.trip_count) + 1: return false
				continue
			var next_index = itinerary.find(entry.destination)
			if next_index <= index or int(entry.trip) != int(value.trip_count) + 1: return false
			index = next_index
	for entry in schedule:
		if float(entry.time) <= previous or float(entry.time) >= float(value.trip_end): return false
		previous = float(entry.time)
	for entry in archive + schedule:
		if entry.destination in Mail.NAMES:
			var key = str(int(entry.trip)) + ":" + entry.destination
			if key in cities: return false
			cities.append(key)
	return true
