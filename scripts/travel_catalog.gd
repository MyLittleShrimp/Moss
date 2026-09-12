class_name TravelCatalog
extends RefCounted

const DESTINATIONS = {"creek": "溪谷", "market": "林间集市", "hill": "山坡", "hangzhou": "杭州·西湖", "tokyo": "东京", "istanbul": "伊斯坦布尔"}
const EVENTS = [
	{"id": "creek_rain", "destination": "creek", "title": "叶子底下的雨声", "text": "溪边下起了小雨。我想起你说喜欢雨声，就在叶子底下多坐了一会儿。这枚青石，替我记住了今天的声音。"},
	{"id": "creek_bridge", "destination": "creek", "title": "小桥边的邮差", "text": "我在小桥旁遇见蜗牛邮差，帮它扶住了被风吹动的信。它指给我一条安静的小路，我在那里挑了一枚青石。原来慢慢走，也能遇见好多事。"},
	{"id": "market_tea", "destination": "market", "title": "借一杯热茶", "text": "集市的茶摊多摆了一张小凳子。摊主请我坐下，听杯口的热气轻轻响。我挑了一枚压住茶单的青石，把这份暖意一起带回家。"},
	{"id": "market_map", "destination": "market", "title": "没有标出来的小路", "text": "旧地图摊的角落，画着一条没有名字的小路。我和摊主约好，下次走给它看。它送我一枚压地图的青石，说迷路时也可以停下来歇歇。"},
	{"id": "hill_cloud", "destination": "hill", "title": "像便当一样的云", "text": "山坡上的云像一只打开的便当盒。我躺在草地上，等它慢慢飘过去。下山时找到一枚圆圆的青石，像是云留给地面的小纽扣。"},
	{"id": "hill_seed", "destination": "hill", "title": "风替种子选方向", "text": "一颗种子落在我的围巾上。我把它放回风里，看它飞过山坡。我带回一枚青石，想把这个关于出发的小故事，讲给窗边的你听。"}
]

static func choose(destination: String, seen: Array, likes_rain: bool) -> Dictionary:
	var candidates: Array = []
	for event in EVENTS:
		if event.destination == destination:
			candidates.append(event)
	# First creek visit retains the original memory payoff; then prefer unseen content.
	if destination == "creek" and likes_rain and "creek_rain" not in seen:
		return EVENTS[0].duplicate(true)
	for event in candidates:
		if event.id not in seen and event.id != "creek_rain":
			return event.duplicate(true)
	for event in candidates:
		if event.id not in seen:
			return event.duplicate(true)
	var last = str(seen.back()) if not seen.is_empty() else ""
	for event in candidates:
		if event.id != last:
			return event.duplicate(true)
	return candidates[0].duplicate(true)

static func valid_event(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for event in EVENTS:
		if value.get("id") == event.id:
			return value.get("destination") == event.destination and value.get("title") is String and value.get("text") is String
	return false
