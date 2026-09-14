extends "res://scripts/growing_world.gd"
## Appearance is earned by discovery, never by generated text.
const OUTFITS = {
	"plain": {"name": "出门的老朋友", "item": "", "route": "", "note": "最初的黄围巾与叶子小包"},
	"hat": {"name": "山风探险帽", "item": "chime", "route": "hill", "note": "把山坡的风戴在头上"},
	"scarf": {"name": "湖色丝围巾", "item": "silk", "route": "hangzhou", "note": "把西湖的水色留在身边"},
	"pack": {"name": "蜗牛探险背包", "item": "oldmap", "route": "market", "note": "装下地图与下一次好奇"},
	"gloves": {"name": "星夜针织手套", "item": "starbell", "route": "tokyo", "note": "从东京带回一双小小星光"},
	"shawl": {"name": "苍山云纹披肩装", "item": "cloudshawl", "route": "dali", "note": "把洱海的云披在肩上"},
	"beret": {"name": "贝雷帽画家装", "item": "iris", "route": "paris", "note": "在街角画下今天的光"},
	"aurora": {"name": "极光毛线帽冬装", "item": "auroraglass", "route": "iceland", "note": "把极夜的一点光带回家"}}
const ROOM_REWARDS = {
	"teacup": {"name": "窗台上的木纹茶杯", "kind": "keepsake", "item": "teacup"},
	"goldseed": {"name": "山坡的春日花盆", "kind": "plant", "item": "flower"},
	"glowstone": {"name": "微光纪念灯", "kind": "decor", "item": "lantern"},
	"ceramic": {"name": "蓝纹旅途的落日地毯", "kind": "rug", "item": "sunset"},
	"tiedye": {"name": "洱海扎染桌布", "kind": "decor", "item": "tiecloth"},
	"coffeecup": {"name": "巴黎纪念咖啡杯", "kind": "decor", "item": "pariscup"},
	"basalt": {"name": "火山石微光灯", "kind": "decor", "item": "stonelamp"}}
const WISHES = {
	"creek": "愿你忙碌的时候，也能听见心里的溪水。",
	"market": "愿每一次偶遇，都有一杯热茶的温度。",
	"hill": "愿风替你吹散烦恼，把好消息轻轻送来。",
	"hangzhou": "愿你的日子像湖水，留得住光，也容得下雨。",
	"tokyo": "愿你在热闹的人间，也有属于自己的小小星空。",
	"istanbul": "愿远方带来新故事，回家的路始终温暖。",
	"dali": "愿你把日子过得像云，有自己的方向，也有停留的自由。",
	"paris": "愿平凡的街角，也有值得你停下来的光。",
	"iceland": "愿漫长的等待，终有一束温柔的光回应你。"}

func fresh() -> Dictionary:
	var value = super.fresh()
	value.schema = 6
	value.outfit = "plain"
	value.claimed_room_rewards = []
	return value

func outfit_unlocked(id: String) -> bool:
	return OUTFITS.has(id) and (id == "plain" or OUTFITS[id].item in data.collected)

func advance(now: float) -> bool:
	var known = data.collected.duplicate()
	var returned = super.advance(now)
	if returned:
		var notes = []
		for id in OUTFITS:
			var item = OUTFITS[id].item
			if item != "" and item in data.collected and item not in known: notes.append("衣橱解锁·" + OUTFITS[id].name)
		for item in ROOM_REWARDS:
			if item in data.collected and item not in known: notes.append("小屋奖励可领取·" + ROOM_REWARDS[item].name)
		if not notes.is_empty():
			data.letters[0].rewards += "、" + "、".join(notes)
			_event("旅行成果：" + "、".join(notes), now)
			persist()
	return returned

func command(action: String, payload: Dictionary = {}, now: float = -1, key: String = "") -> Dictionary:
	if action == "place":
		var result = super.command(action, payload, now, key)
		if result.ok:
			data.window_cup = false
			persist()
		return result
	if action not in ["wear", "claim_room_reward", "window_cup"]: return super.command(action, payload, now, key)
	if now < 0: now = clock()
	advance(now)
	if not key.is_empty() and key in data.processed: return _fail("这次操作已经处理过啦。")
	var id = str(payload.get("item", ""))
	var message = ""
	if action == "window_cup":
		if "teacup" not in data.claimed_room_rewards: return _fail("先领取木纹茶杯的小屋奖励吧。")
		data.window_cup = not data.get("window_cup", false)
		if data.window_cup: data.placed = false
		message = "把木纹茶杯摆上窗台，青石先收进收藏。" if data.window_cup else "收起茶杯，给窗台留一点空白。"
	elif action == "wear":
		if not outfit_unlocked(id): return _fail("先找到对应旅行宝物，再来试穿吧。")
		data.outfit = id
		message = "换上了" + OUTFITS[id].name + "。收藏会一直保留。"
	else:
		if not ROOM_REWARDS.has(id) or id not in data.collected: return _fail("还没有找到这份旅行纪念。")
		if id in data.claimed_room_rewards: return _fail("这份奖励已经收下了，在小屋里随时摆放。")
		var gift = ROOM_REWARDS[id]
		if gift.kind == "plant":
			if gift.item not in data.plant_styles: data.plant_styles.append(gift.item)
			if "plant" not in data.decorations: data.decorations.append("plant")
		elif gift.kind == "rug":
			if gift.item not in data.rugs: data.rugs.append(gift.item)
		elif gift.kind == "decor" and gift.item not in data.decorations: data.decorations.append(gift.item)
		data.claimed_room_rewards.append(id)
		message = "收下了" + gift.name + "，去「小屋」摆放吧。宝物无需消耗；已拥有的款式不会重复发放。"
	if not key.is_empty():
		data.processed.append(key)
		if data.processed.size() > 100: data.processed.pop_front()
	data.revision += 1
	persist()
	return {"ok": true, "message": message}

func postcard_content(id: String) -> Dictionary:
	if id not in data.postcards or not Content.ROUTES.has(id): return {}
	for letter in data.letters:
		if letter.get("destination") == id and not str(letter.get("event_id", "")).ends_with("_forgot"):
			return {"title": Content.ROUTES[id].name, "text": narrative_text(letter), "source": narrative_source(letter), "wish": WISHES[id], "trip": "第 %d 次旅行" % letter.trip, "date": today(float(letter.get("time", clock())))}
	return {"title": Content.ROUTES[id].name, "text": "整理旧相册时，发现了这张从远方带回的风景。那时的详细手记已经不在了，见过的世界仍留在这里。", "wish": WISHES[id], "trip": "旧日相册", "date": "日期未记录"}

func migrate(value: Variant) -> Variant:
	if not value is Dictionary: return value
	var result = value if value.get("schema") == 5 else super.migrate(value)
	if not result is Dictionary or result.get("schema") != 5: return result
	result = result.duplicate(true)
	result.schema = 6
	result.outfit = "plain"
	result.claimed_room_rewards = []
	return result

func valid_save(value: Variant) -> bool:
	if not value is Dictionary or value.get("schema") != 6: return false
	if not value.get("window_cup", false) is bool: return false
	if value.get("window_cup", false) and (value.get("placed", false) or "teacup" not in value.get("claimed_room_rewards", [])): return false
	var base = value.duplicate(true)
	base.schema = 5
	if not super.valid_save(base): return false
	if not OUTFITS.has(value.get("outfit")): return false
	if value.outfit != "plain" and OUTFITS[value.outfit].item not in value.collected: return false
	if not value.get("claimed_room_rewards") is Array or value.claimed_room_rewards.size() > ROOM_REWARDS.size(): return false
	var seen = []
	for id in value.claimed_room_rewards:
		if not ROOM_REWARDS.has(id) or id not in value.collected or id in seen: return false
		seen.append(id)
		var gift = ROOM_REWARDS[id]
		if gift.kind == "plant" and (gift.item not in value.plant_styles or "plant" not in value.decorations): return false
		if gift.kind == "rug" and gift.item not in value.rugs: return false
		if gift.kind == "decor" and gift.item not in value.decorations: return false
	return true
