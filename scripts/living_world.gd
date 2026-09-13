extends "res://scripts/expanded_world.gd"
## Small home rituals are persistent, never an income grind or neglect penalty.
const PLANTS = {"leaf": {"name": "常青小盆栽", "price": 0, "art": "plant"}, "flower": {"name": "春日花盆", "price": 12, "art": "flower"}}
const RUGS = {"woven": {"name": "原色编织毯", "price": 0}, "meadow": {"name": "苔绿叶纹毯", "price": 14}, "sunset": {"name": "暖杏落日毯", "price": 18}}
const SPOTS = {"window": "窗边", "desk": "书桌旁", "door": "门口"}
const WEATHER_NAMES = {"sunny": "晴天", "cloudy": "阴天", "rainy": "小雨"}
const BOOK = ["小屋观察手册\n\n不用把每一天都安排满。\n种子慢慢长，风慢慢吹。\n偶尔发一会儿呆，也很好。", "给远方的一页\n\n便当里装着今天的收成，\n明信片里装着路上的风景。\n有些绕路，会遇见朋友。", "雨天的一页\n\n把盆栽挪到看得见雨的地方，\n扫掉门边一点落叶。\n今天的小屋，也值得被好好记住。"]

func fresh() -> Dictionary:
	var value = super.fresh()
	value.schema = 4
	value.merge({"plant_styles": ["leaf"], "plant_style": "leaf", "plant_spot": "window",
		"rugs": ["woven", "meadow", "sunset"], "rug": "woven", "book_page": 0, "cleanliness": 100,
		"last_sweep": 0.0, "dust_tick": 0.0, "weather": {"kind": "sunny", "humidity": 52, "slot": -1}})
	return value

static func weather_at(now: float) -> Dictionary:
	var slot = floori(now / 1800.0)
	var weather_rng = RandomNumberGenerator.new()
	weather_rng.seed = slot * 7919 + 202609
	var roll = weather_rng.randf()
	var kind = "sunny" if roll < 0.45 else ("cloudy" if roll < 0.72 else "rainy")
	var humidity = weather_rng.randi_range(42, 59) if kind == "sunny" else (weather_rng.randi_range(60, 74) if kind == "cloudy" else weather_rng.randi_range(78, 92))
	return {"kind": kind, "humidity": humidity, "slot": slot}

func advance(now: float) -> bool:
	var returned = super.advance(now)
	now = maxf(now, float(data.last_seen))
	var changed = false
	for id in ["meadow", "sunset"]:
		if id not in data.rugs: data.rugs.append(id); changed = true
	var weather = weather_at(now)
	if data.weather.slot != weather.slot:
		data.weather = weather
		changed = true
	if data.dust_tick == 0: data.dust_tick = now
	var hours = floori((now - float(data.dust_tick)) / 3600)
	if hours > 0:
		data.cleanliness = maxi(40, int(data.cleanliness) - mini(hours, 12) * 5)
		data.dust_tick = now
		changed = true
	if changed:
		data.revision += 1
		persist()
	return returned

func command(action: String, payload: Dictionary = {}, now: float = -1.0, key: String = "") -> Dictionary:
	if action not in ["home_buy", "plant_style", "plant_move", "rug", "read_book", "sweep"]:
		return super.command(action, payload, now, key)
	if now < 0: now = clock()
	advance(now)
	now = maxf(now, float(data.last_seen))
	if not key.is_empty() and key in data.processed: return _fail("这次操作已经做过啦。")
	var message = ""
	var item = str(payload.get("item", ""))
	match action:
		"home_buy":
			var kind = str(payload.get("kind", ""))
			if kind not in ["plant", "rug"]: return _fail("没有这种小屋用品。")
			var catalog = PLANTS if kind == "plant" else RUGS
			var owned = data.plant_styles if kind == "plant" else data.rugs
			if not catalog.has(item) or item in owned: return _fail("已经拥有，或没有这件物品。")
			if data.coins < catalog[item].price: return _fail("叶币还不够，先收集一些旅途回忆吧。")
			data.coins -= catalog[item].price
			owned.append(item)
			if kind == "plant":
				data.plant_style = item
				if "plant" not in data.decorations: data.decorations.append("plant")
				if "plant" not in data.equipped: data.equipped.append("plant")
			else: data.rug = item
			message = "换上了" + catalog[item].name + "。"
		"plant_style":
			if item not in data.plant_styles or "plant" not in data.decorations: return _fail("先在小铺挑一盆喜欢的植物。")
			data.plant_style = item
			if "plant" not in data.equipped: data.equipped.append("plant")
			message = "换上" + PLANTS[item].name + "。"
		"plant_move":
			if "plant" not in data.equipped or not SPOTS.has(item): return _fail("先摆出盆栽，再选一个位置。")
			data.plant_spot = item
			message = "把盆栽挪到" + SPOTS[item] + "，这里也有好风景。"
		"rug":
			if item not in data.rugs: return _fail("还没有这张地毯。")
			data.rug = item
			message = "铺上" + RUGS[item].name + "。"
		"read_book":
			var page = int(payload.get("page", 0))
			if page < 0 or page >= BOOK.size(): return _fail("这本小书只有三页。")
			data.book_page = page
			message = "翻开了小屋观察手册。"
		"sweep":
			if now - float(data.last_sweep) < 2: return _fail("慢慢扫，落叶马上就收好了。")
			data.cleanliness = mini(100, int(data.cleanliness) + 25)
			data.last_sweep = now
			message = "沙沙——扫掉一点落叶，心里也轻了一点。"
	if not key.is_empty():
		data.processed.append(key)
		if data.processed.size() > 100: data.processed.pop_front()
	data.revision += 1
	_event(message, now)
	persist()
	return {"ok": true, "message": message, "revision": data.revision}

func migrate(value: Variant) -> Variant:
	if not value is Dictionary: return value
	var result = value
	if value.get("schema") == 1 or value.get("schema") == 2: result = super.migrate(value)
	if not result is Dictionary or result.get("schema") != 3: return result
	result = result.duplicate(true)
	var defaults = fresh()
	for field in ["plant_styles", "plant_style", "plant_spot", "rugs", "rug", "book_page", "cleanliness", "last_sweep", "dust_tick", "weather"]:
		result[field] = defaults[field]
	result.schema = 4
	return result

func valid_save(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != 4: return false
	var base = value.duplicate(true)
	base.schema = 3
	if not super.valid_save(base): return false
	if not value.plant_styles is Array or not value.rugs is Array: return false
	for id in value.plant_styles:
		if not PLANTS.has(id): return false
	for id in value.rugs:
		if not RUGS.has(id): return false
	if value.plant_style not in value.plant_styles or value.rug not in value.rugs or not SPOTS.has(value.plant_spot): return false
	if not natural(value.book_page) or value.book_page >= BOOK.size() or not natural(value.cleanliness) or value.cleanliness > 100: return false
	if not numeric(value.last_sweep) or not numeric(value.dust_tick): return false
	var weather = value.weather
	return weather is Dictionary and WEATHER_NAMES.has(weather.get("kind")) and natural(weather.get("humidity")) and weather.humidity <= 100 and (natural(weather.get("slot")) or weather.get("slot") == -1)
