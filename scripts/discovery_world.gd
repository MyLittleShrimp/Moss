extends "res://scripts/reward_world.gd"
## Discovery is persisted with settlement; opening a parcel never grants loot twice.
func fresh() -> Dictionary:
	var value = super.fresh()
	value.schema = 7
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

func roll_rare(destination: String) -> String:
	var misses = int(data.rare_misses[destination])
	var chance = minf(1.0, float(Content.ROUTES[destination].chance) + maxf(0, misses - 2) * 0.12)
	if release_timing and rare_guarantee(destination) == 3: chance = minf(1.0, float(Content.ROUTES[destination].chance) + misses * 0.25)
	return Content.ROUTES[destination].rare if misses >= rare_guarantee(destination) - 1 or rng.randf() < chance else ""

func rare_guarantee(destination: String) -> int:
	return 3 if release_timing and destination in ["tokyo", "istanbul", "paris", "iceland"] else 8

func advance(now: float) -> bool:
	if float(data.trip_end) > 0 and maxf(now, data.last_seen) >= float(data.trip_end) and data.trip_snapshot.get("incident") != "forgot":
		var destination = str(data.active_event.destination)
		data.rare_misses[destination] = 0 if data.trip_snapshot.get("rare", "") != "" else mini(7, int(data.rare_misses[destination]) + 1)
	return super.advance(now)

func command(action: String, payload: Dictionary = {}, now: float = -1, key: String = "") -> Dictionary:
	if now < 0: now = clock()
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
	if not super.valid_save(base): return false
	if not value.pending_discoveries is Array or value.pending_discoveries.size() > Content.ITEMS.size() or not value.rare_misses is Dictionary: return false
	var seen = []
	for item in value.pending_discoveries:
		if item not in value.collected or item in seen: return false
		seen.append(item)
	for id in Content.ROUTES:
		if not natural(value.rare_misses.get(id)) or value.rare_misses[id] > 7: return false
	if value.trip_snapshot.has("snack") and not value.trip_snapshot.snack is bool: return false
	return true
