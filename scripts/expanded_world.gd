class_name ExpandedWorld
extends "res://scripts/world.gd"
## G5 state owns rewards. Narration and model responses never execute mutations.
const Content = preload("res://scripts/game_content.gd")
var rng = RandomNumberGenerator.new()
var release_timing = false
const Timing = preload("res://scripts/build_profile.gd")

func balanced_timing() -> bool:
	return release_timing or data.pace == "balanced"

func pace_scale() -> float:
	return 60.0 if not release_timing and data.pace == "balanced" else 1.0

func crop_seconds(id: String) -> float:
	return float(Timing.CROPS[id]) / pace_scale() if balanced_timing() else float(Content.CROPS[id].seconds) / (10.0 if data.pace == "demo" else 1.0)

func trip_bounds(id: String) -> Array:
	return Timing.TRIPS[id] if balanced_timing() else [Content.ROUTES[id].min, Content.ROUTES[id].max]

func _init(path: String = "") -> void:
	rng.randomize()
	super(path)

func fresh() -> Dictionary:
	var value = super.fresh()
	value.schema = 3
	value.merge({"ingredients": {"herb": 0, "rice": 0, "mushroom": 0, "pumpkin": 0},
		"foods": {"herb_box": 0, "rice_ball": 0, "mushroom_box": 0, "feast": 0},
		"plot_crops": ["herb", "herb", "herb"], "items": {}, "collected": [],
		"postcards": [], "coins": 10, "decorations": [], "equipped": [], "themes": ["spring"],
		"theme": "spring", "condition": "well", "recovery_end": 0.0, "pace": "normal", "trip_snapshot": {}})
	for id in Content.CROPS: value.ingredients[id] = 0
	for id in Content.FOODS: value.foods[id] = 0
	return value

func sync_aliases() -> void:
	data.herbs = int(data.ingredients.herb)
	data.meals = 0
	for count in data.foods.values(): data.meals += int(count)
	data.souvenirs = int(data.items.get("stone", 0))

func give(item: String) -> void:
	data.items[item] = int(data.items.get(item, 0)) + 1
	if item not in data.collected: data.collected.append(item)

func advance(now: float) -> bool:
	now = maxf(now, float(data.last_seen))
	data.last_seen = now
	var changed = false
	if data.condition != "well" and now >= float(data.recovery_end):
		data.condition = "well"
		data.recovery_end = 0.0
		_event("睡了一觉，苔苔又精神起来了。", now)
		changed = true
	var returned = float(data.trip_end) > 0 and now >= float(data.trip_end)
	if returned:
		var arrival = float(data.trip_end)
		var trip = data.trip_snapshot
		var event = data.active_event
		data.trip_end = 0.0
		data.trip_count += 1
		var rewards: Array[String] = []
		if trip.get("incident", "ordinary") != "forgot":
			var destination = str(event.destination)
			var common = str(trip.get("common", "stone"))
			give(common)
			rewards.append(Content.ITEMS[common].name)
			var rare = str(trip.get("rare", ""))
			if not rare.is_empty():
				give(rare)
				rewards.append("隐藏收藏·" + Content.ITEMS[rare].name)
			if destination not in data.postcards: data.postcards.append(destination)
		else:
			# Unused food returns; no destination reward or postcard for an aborted trip.
			var packed = trip.get("provisions", {str(trip.food): int(trip.portions)})
			for id in packed: data.foods[id] += int(packed[id])
			if trip.get("snack", false): data.foods.berry_snack += 1
			rewards.append("未用的食物已放回厨房")
		data.letters.push_front({"text": event.text, "title": event.title, "destination": event.destination,
			"event_id": event.id, "trip": data.trip_count, "time": now, "rewards": "、".join(rewards)})
		if data.letters.size() > 60: data.letters.resize(60)
		data.visited_event_ids.append(event.id)
		if data.visited_event_ids.size() > 120: data.visited_event_ids.pop_front()
		var incident = str(trip.get("incident", "ordinary"))
		if incident in ["ill", "mood"]:
			var recovery = arrival + float(trip.get("recovery_seconds", 600))
			if now < recovery:
				data.condition = incident
				data.recovery_end = recovery
		data.trip_snapshot = {}
		data.active_event = {}
		_event("苔苔回家了：" + "、".join(rewards), now)
		changed = true
	if changed:
		sync_aliases()
		data.revision += 1
		persist()
	return returned

func command(action: String, payload: Dictionary = {}, now: float = -1.0, key: String = "") -> Dictionary:
	if now < 0: now = clock()
	advance(now)
	now = maxf(now, float(data.last_seen))
	if not key.is_empty() and key in data.processed: return _fail("这次操作已经处理过啦。")
	var message = ""
	match action:
		"garden":
			var plot = int(payload.get("plot", -1))
			if plot < 0 or plot > 2: return _fail("找不到这块田地。")
			if float(data.plots[plot]) == 0:
				var crop = str(payload.get("crop", "herb"))
				if not Content.CROPS.has(crop): return _fail("没有这种种子。")
				data.plot_crops[plot] = crop
				data.plots[plot] = now + crop_seconds(crop)
				message = "种下%s，种子免费，成熟后不会枯萎。" % Content.CROPS[crop].name
			elif now >= float(data.plots[plot]):
				var crop = str(data.plot_crops[plot])
				data.ingredients[crop] += int(Content.CROPS[crop].yield)
				data.plots[plot] = 0.0
				message = "收获%s × %d。" % [Content.CROPS[crop].name, Content.CROPS[crop].yield]
			else: return _fail("它正在生长，成熟后再来。")
		"cook":
			var food = str(payload.get("food", "herb_box"))
			if not Content.FOODS.has(food): return _fail("还没有这份食谱。")
			var recipe = Content.FOODS[food].recipe
			for crop in recipe:
				if data.ingredients[crop] < recipe[crop]: return _fail("食材不足，需要：" + Content.recipe_text(food))
			for crop in recipe: data.ingredients[crop] -= recipe[crop]
			data.foods[food] += 1
			message = Content.FOODS[food].name + "做好了。"
		"travel":
			var destination = str(payload.get("destination", "creek"))
			var check = travel_check(destination, payload)
			if not check.ok: return _fail(check.message)
			var packed = check.provisions
			var food = str(packed.keys()[0])
			var portions = int(packed[food])
			var snack = bool(payload.get("snack", false))
			var route = Content.ROUTES[destination]
			var incident = Content.incident(rng.randf())
			var actual = destination
			if incident == "friend":
				actual = {"creek": "creek", "market": "creek", "hill": "market", "hangzhou": "hill", "tokyo": "hangzhou", "istanbul": "tokyo", "dali": "hill", "paris": "istanbul", "iceland": "paris"}[destination]
			var bounds = trip_bounds(destination)
			var duration = rng.randf_range(bounds[0], bounds[1])
			if incident == "rain": duration *= 1.3
			if incident == "friend": duration *= 1.15
			if incident == "forgot":
				if destination in Content.LONG_ROUTES and balanced_timing(): duration = rng.randf_range(3600.0, 57600.0)
				else: duration *= 0.2
			if balanced_timing(): duration = minf(duration, bounds[1]) / pace_scale()
			elif data.pace == "demo": duration /= 60.0
			var actual_route = Content.ROUTES[actual]
			var rare = roll_rare(actual, snack)
			for id in packed: data.foods[id] -= int(packed[id])
			if snack: data.foods.berry_snack -= 1
			data.trip_end = now + duration
			data.trip_rain = data.rain_preference == "like"
			data.trip_snapshot = {"planned": destination, "incident": incident, "common": actual_route.common,
				"rare": rare, "food": food, "portions": portions, "provisions": packed.duplicate(true), "pace": data.pace,
				"recovery_seconds": 600.0 / pace_scale() if balanced_timing() else (20 if data.pace == "demo" else 600), "snack": snack,
				"mail_gap": 172800.0 / pace_scale() if balanced_timing() else 172800.0 * float(bounds[1]) / float(Timing.TRIPS[destination][1]) / (60.0 if data.pace == "demo" else 1.0)}
			data.active_event = {"id": "g5_" + actual + "_" + incident, "destination": actual,
				"title": Content.INCIDENTS[incident], "text": story(actual, incident)}
			if snack and incident != "forgot" and rng.randf() < 0.35: data.active_event.text += "路边的小鸟闻到了草莓香，我分给它一点点心，它陪我走过了一小段路。"
			message = "苔苔背着" + provisions_text(packed) + "出发了。归期未定，关掉游戏旅程也会继续。"
		"sell":
			var item = str(payload.get("item", ""))
			if not Content.ITEMS.has(item) or int(data.items.get(item, 0)) <= 1: return _fail("只兑换重复收藏，第一件会留下。")
			data.items[item] -= 1
			data.coins += int(Content.ITEMS[item].value)
			message = "用一件重复收藏换来了叶币。图鉴仍然保留。"
		"buy":
			var item = str(payload.get("item", ""))
			var kind = str(payload.get("kind", ""))
			var price = 0
			match kind:
				"crop":
					if not Content.CROPS.has(item): return _fail("没有这件商品。")
					price = Content.CROP_PRICES[item]
				"food":
					if not Content.FOODS.has(item): return _fail("没有这件商品。")
					price = Content.food_price(item)
				"decor":
					if not Content.DECOR.has(item) or item in data.decorations: return _fail("这件布置已经有了，或不存在。")
					if Content.DECOR[item].get("reward_only", false): return _fail("这件纪念布置需要旅行发现，不能购买。")
					price = Content.DECOR[item].price
				"theme":
					if not Content.THEMES.has(item) or item in data.themes: return _fail("这个季节布置已经有了，或不存在。")
					price = 10
				_: return _fail("没有这类商品。")
			if data.coins < price: return _fail("叶币不足，可兑换重复收藏；种子一直免费。")
			data.coins -= price
			match kind:
				"crop": data.ingredients[item] += 1
				"food": data.foods[item] += 1
				"decor":
					data.decorations.append(item)
					data.equipped.append(item)
				"theme": data.themes.append(item)
			message = "兑换好了，放进你的收藏。"
		"decorate":
			var item = str(payload.get("item", ""))
			if item not in data.decorations: return _fail("还没有这件布置。")
			if item in data.equipped: data.equipped.erase(item)
			else: data.equipped.append(item)
			message = "小屋换了一点模样。"
		"theme":
			var item = str(payload.get("item", ""))
			if item not in data.themes: return _fail("先在小铺兑换这个季节吧。")
			data.theme = item
			message = "换上" + Content.THEMES[item] + "。"
		"care":
			if float(data.trip_end) > 0: return _fail("等苔苔回家再陪它坐坐吧。")
			if data.condition == "well": return _fail("苔苔精神很好，正等你讲个小故事。")
			if data.condition == "ill":
				if data.ingredients.herb < 1: return _fail("一份香草能煮热汤；也可以让它睡一觉，自然恢复。")
				data.ingredients.herb -= 1
			data.condition = "well"
			data.recovery_end = 0.0
			message = "陪伴和热乎乎的小日子，让苔苔恢复了精神。"
		"pace":
			if release_timing: return _fail("发布版采用慢生活节奏。")
			var pace = str(payload.get("pace", "normal"))
			if pace not in ["normal", "demo", "balanced"]: return _fail("未知节奏。")
			data.pace = pace
			message = "已切换节奏，仅影响之后播种和出发的旅程。"
		"place", "remember":
			return super.command(action, payload, now, key)
		_: return _fail("这个动作还不在小屋的规则里。")
	if not key.is_empty():
		data.processed.append(key)
		if data.processed.size() > 100: data.processed.pop_front()
	sync_aliases()
	data.revision += 1
	_event(message, now)
	persist()
	return {"ok": true, "message": message, "revision": data.revision}

func provisions_text(packed: Dictionary) -> String:
	var parts: Array[String] = []
	for id in packed: parts.append("%s × %d" % [Content.FOODS[id].name, packed[id]])
	return "、".join(parts)

func travel_check(destination: String, payload: Dictionary) -> Dictionary:
	if not Content.ROUTES.has(destination): return _fail("请选择目的地。")
	var packed = payload.get("provisions", null)
	if not payload.has("provisions"):
		var food = str(payload.get("food", "herb_box"))
		if not Content.FOODS.has(food): return _fail("行程或食物不存在。")
		packed = {food: Content.portions(destination, food)}
	if not packed is Dictionary or packed.is_empty(): return _fail("请用下方计数器装入便当。")
	var total = 0
	for id in packed:
		if not Content.FOODS.has(id) or Content.FOODS[id].get("snack", false): return _fail("点心不能代替主便当。")
		if not natural(packed[id]) or packed[id] < 1 or packed[id] > 10000: return _fail("便当数量需为1–10000之间的整数。")
		if Content.FOODS[id].tier < Content.ROUTES[destination].tier: return _fail(Content.FOODS[id].name + "耐放等级不足。")
		if data.foods[id] < packed[id]: return _fail(Content.FOODS[id].name + "库存不足。")
		total += int(packed[id]) * int(Content.FOODS[id].nutrition)
	if not payload.get("snack", false) is bool: return _fail("点心选项无效。")
	if payload.get("snack", false) and data.foods.berry_snack < 1: return _fail("还没有草莓点心包。")
	if data.trip_end > 0: return _fail("苔苔已经在路上了。")
	if data.condition != "well": return _fail("苔苔想先休息一会儿。")
	if total < Content.ROUTES[destination].supply: return _fail("补给不足：%d / %d。" % [total, Content.ROUTES[destination].supply])
	return {"ok":true, "message":"行囊准备好了", "provisions":packed, "supply":total}

func rare_chance(destination: String, snack: bool = false) -> float:
	return minf(1.0, float(Content.ROUTES[destination].chance) + (0.15 if snack else 0.0))

func roll_rare(destination: String, snack: bool = false) -> String:
	return Content.ROUTES[destination].rare if rng.randf() < rare_chance(destination, snack) else ""

func story(destination: String, incident: String) -> String:
	if incident == "forgot":
		var moments = ["回头时遇见一只推着松果的小松鼠。我帮它推过坡，它送了我一声响亮的谢谢。", "等返程的车时，雨在站牌上敲出一支小曲。我用树叶接了一滴，忽然不觉得白跑了。", "路边卖面包的阿姨认出了我的围巾，教我在日记本上画一个提醒自己的小结。"]
		return "日记本还落在桌上，我决定先回家。" + moments[rng.randi_range(0, moments.size() - 1)] + "虽然没到目的地，食物完整带回，也带回了这个小故事。"
	var scenes = {"creek": "溪水把石头洗得亮亮的，我在桥边听了一会儿水声。", "market": "茶摊的主人留了一张小凳子，热茶里有森林的气味。", "hill": "风把蒲公英种子送向远方，我躺在草地上替它们选方向。", "hangzhou": "西湖的柳枝轻轻碰到水面，我从石桥这头慢慢走到那头。", "tokyo": "在东京的樱花树下，我看着红色高塔，听电车从远处经过。", "istanbul": "渡轮划过海峡，远处的圆顶映着落日，我在小店挑了一片蓝纹陶。"}
	scenes.merge({"dali": "洱海的水把白云轻轻托住。晾在院子里的扎染布随风飘动，我坐在花田边，终于学会把一个下午慢慢过完。", "paris": "面包店刚开门，街角飘来温热的香气。我沿着河岸走，看到屋顶留住最后一点夕光，原来平凡的一天也值得画下来。", "iceland": "彩色小屋的窗灯亮着，港口安静得能听见雪落下。等了很久，天空终于划过一点绿色的光，我把那一刻记在心里。"})
	var text = str(scenes[destination])
	match incident:
		"rain": text += "途中下了雨，我在屋檐下多等了一阵。" + ("想起你喜欢雨声，便替你多听了一会儿。" if data.trip_rain else "雨停以后，路面闪着光。")
		"friend": text = "半路遇见老朋友，改去近一点的地方喝茶；行囊里的食物够用。" + text
		"ill": text += "回来时有点着凉，想喝一碗香草汤，再睡一觉。"
		"mood": text += "热闹过后，我想安静坐一会儿。你陪着就好。"
	return text

func migrate(value: Variant) -> Variant:
	if not value is Dictionary or (value.get("schema") != 1 and value.get("schema") != 2): return value
	for field in ["herbs", "meals", "souvenirs", "plots", "trip_end", "trip_rain", "letters", "placed", "rain_preference", "memory_source", "events", "processed", "last_seen", "revision", "trip_count", "name"]:
		if not value.has(field): return null
	if not value.letters is Array or not numeric(value.trip_end) or not natural(value.herbs) or not natural(value.meals) or not natural(value.souvenirs): return null
	var result = value.duplicate(true)
	var defaults = fresh()
	# Expanded fields cannot be smuggled into a legacy schema; derive them once.
	for field in ["ingredients", "foods", "plot_crops", "items", "collected", "postcards", "coins", "decorations", "equipped", "themes", "theme", "condition", "recovery_end", "pace", "trip_snapshot"]:
		result[field] = defaults[field]
	for field in defaults:
		if not result.has(field): result[field] = defaults[field]
	result.schema = 3
	result.ingredients.herb = result.herbs
	result.foods.herb_box = result.meals
	result.items.stone = result.souvenirs
	if result.souvenirs > 0: result.collected.append("stone")
	for letter in result.letters:
		if letter is Dictionary:
			var destination = str(letter.get("destination", "creek"))
			if Content.ROUTES.has(destination) and destination not in result.postcards: result.postcards.append(destination)
	if float(result.trip_end) > 0 and result.active_event.is_empty():
		result.active_event = Catalog.choose("creek", [], bool(result.trip_rain))
	return result

func valid_save(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != 3: return false
	for field in fresh():
		if not value.has(field): return false
	for field in ["ingredients", "foods", "items", "trip_snapshot", "active_event"]:
		if not value[field] is Dictionary: return false
	for pair in [["ingredients", Content.CROPS], ["foods", Content.FOODS]]:
		for id in pair[1]:
			if not natural(value[pair[0]].get(id)): return false
	for id in value.items:
		if not Content.ITEMS.has(id) or not natural(value.items[id]): return false
	for field in ["herbs", "meals", "souvenirs", "coins", "trip_count", "revision"]:
		if not natural(value[field]): return false
	for field in ["trip_end", "last_seen", "recovery_end"]:
		if not numeric(value[field]): return false
	if not value.plots is Array or value.plots.size() != 3 or not value.plot_crops is Array or value.plot_crops.size() != 3: return false
	for i in range(3):
		if not numeric(value.plots[i]) or not Content.CROPS.has(value.plot_crops[i]): return false
	for pair in [["collected", Content.ITEMS], ["postcards", Content.ROUTES], ["decorations", Content.DECOR], ["equipped", Content.DECOR], ["themes", Content.THEMES]]:
		if not value[pair[0]] is Array: return false
		for id in value[pair[0]]:
			if not pair[1].has(id): return false
	for id in value.equipped:
		if id not in value.decorations: return false
	if value.theme not in value.themes or value.condition not in ["well", "ill", "mood"] or value.pace not in ["normal", "demo", "balanced"]: return false
	for field in ["letters", "events", "processed", "visited_event_ids"]:
		if not value[field] is Array: return false
	for entry in value.letters:
		if not entry is Dictionary or not entry.get("text") is String or not natural(entry.get("trip")): return false
	for entry in value.events:
		if not entry is Dictionary or not entry.get("text") is String: return false
	if float(value.trip_end) > 0:
		var event = value.active_event
		if not Content.ROUTES.has(event.get("destination")) or not event.get("id") is String or not event.get("text") is String or not event.get("title") is String: return false
		var trip = value.trip_snapshot
		if not trip.is_empty():
			if not Content.ROUTES.has(trip.get("planned")) or not Content.INCIDENTS.has(trip.get("incident")) or not Content.FOODS.has(trip.get("food")): return false
			if not natural(trip.get("portions")) or not Content.ITEMS.has(trip.get("common")) or (trip.get("rare") != "" and not Content.ITEMS.has(trip.get("rare"))): return false
			if not numeric(trip.get("recovery_seconds")): return false
			if trip.has("provisions"):
				if not trip.provisions is Dictionary or trip.provisions.is_empty(): return false
				var supply = 0
				for id in trip.provisions:
					if not Content.FOODS.has(id) or Content.FOODS[id].get("snack", false): return false
					if not natural(trip.provisions[id]) or trip.provisions[id] < 1 or trip.provisions[id] > 10000: return false
					if Content.FOODS[id].tier < Content.ROUTES[trip.planned].tier: return false
					supply += int(trip.provisions[id]) * int(Content.FOODS[id].nutrition)
				if supply < Content.ROUTES[trip.planned].supply: return false
	return value.placed is bool and value.trip_rain is bool and value.name is String and value.memory_source is String and value.rain_preference in ["like", "dislike", "unknown"]

func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0

func natural(value: Variant) -> bool:
	return numeric(value) and float(value) == floorf(float(value))
