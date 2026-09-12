extends RefCounted
## Fictional multi-city sightseeing routes; not a live airline timetable.
const ROUTES = {"tokyo": ["shanghai"], "istanbul": ["shanghai", "dubai"], "paris": ["shanghai", "dubai", "london"]}
const NAMES = {"shanghai": "上海", "dubai": "迪拜", "london": "伦敦", "stockholm": "斯德哥尔摩", "copenhagen": "哥本哈根"}
const NOTES = {
	"shanghai": ["在外滩坐了一会儿，看船从江面慢慢经过。出发前留了一点时间给这座城市，江风把围巾吹得鼓鼓的。把这张沿途的风景先寄给你。", "到上海后没有急着继续赶路。我捧着热饮看了一会儿江对岸的楼，想起小屋窗前也有很好看的光。新的旅程，从这样的片刻开始。"],
	"dubai": ["这一站是迪拜。沿着河湾走了一小段，看木船轻轻靠岸，沙色的房子被夕阳照得很暖。停下来歇脚时，刚好够我写一张明信片。", "在迪拜河边等风凉下来，听见船声和远处的交谈。不同地方的傍晚，原来也各有自己的颜色。这一抹金色，想寄回小屋。"],
	"london": ["伦敦落了一点细雨，我撑着伞在泰晤士河边慢慢走。远处钟楼的轮廓从云下露出来，脚边的水洼也装着一小片天空。", "今天在伦敦停一停。河边的风有些凉，喝完一杯热茶再散步，倒觉得这样的慢节奏很合适。把路上遇见的光亮寄给你。"],
	"stockholm": ["到了斯德哥尔摩，旧城的暖色房子映在水里。我坐在码头边吃一小块肉桂面包，看渡船把波纹带向远处。这是很安静的一站。", "斯德哥尔摩的水面把天空映得好大。沿着旧城走走停停，给旅程留出一点空白，也给你留出这张小小的风景。"],
	"copenhagen": ["在哥本哈根的新港歇脚，运河边的彩色房子像排好的一盒彩笔。自行车轻轻经过，我坐在岸边，把这段明亮的小日子写下来。", "今天留给哥本哈根。沿着运河走了一会儿，木船在水上轻轻晃，面包还是温热的。旅程里的这些小事，也很值得与你分享。"]}

static func city_name(id: String) -> String:
	return NAMES.get(id, GameContent.ROUTES.get(id, {}).get("name", "途中"))

static func prepare(world, now: float) -> void:
	if not world.data.has("travel_mail"): world.data.travel_mail = []
	if float(world.data.trip_end) <= 0: return
	var trip = world.data.trip_snapshot
	if trip.get("mail_route_version") == 2: return
	trip.mail_route_version = 2
	trip.mail_schedule = []
	trip.mail_route = []
	var destination = str(world.data.active_event.destination)
	if trip.get("incident") == "forgot": return
	var points = ROUTES.get(destination, []).duplicate()
	if destination == "iceland": points = ["shanghai", "dubai", "london", "stockholm" if world.rng.randf() < 0.5 else "copenhagen"]
	trip.mail_route = points.duplicate()
	if points.is_empty(): return
	# Old in-flight saves begin their new correspondence from upgrade time, never backdate it.
	var remaining = float(world.data.trip_end) - now
	if remaining <= 0: return
	var already_sent = []
	for letter in world.data.travel_mail:
		if int(letter.trip) == int(world.data.trip_count) + 1: already_sent.append(letter.destination)
	for i in range(points.size()):
		var city = points[i]
		if city in already_sent: continue
		var time = now + remaining * (i + world.rng.randf_range(0.65, 1.0)) / (points.size() + 1)
		var chance = world.rng.randf()
		if chance >= 0.9: continue
		var kind = "postcard" if chance < 0.78 else "letter"
		trip.mail_schedule.append({"id": "%d:%d:%s" % [int(world.data.trip_count) + 1, int(world.data.trip_end), city],
			"time": time, "destination": city, "trip": int(world.data.trip_count) + 1,
			"kind": kind, "text": NOTES[city][world.rng.randi_range(0, NOTES[city].size() - 1)], "read": false})

static func deliver(world, now: float) -> int:
	prepare(world, now)
	var count = 0
	var schedule = world.data.trip_snapshot.get("mail_schedule", [])
	while not schedule.is_empty() and float(schedule[0].time) <= now:
		world.data.travel_mail.push_front(schedule.pop_front())
		count += 1
	if world.data.travel_mail.size() > 60: world.data.travel_mail.resize(60)
	if count > 0: world.data.revision += 1
	return count

static func valid(entry: Variant, world) -> bool:
	return entry is Dictionary and entry.get("id") is String and entry.id.length() < 100 and world.numeric(entry.get("time")) and world.natural(entry.get("trip")) and (entry.get("destination") in NAMES or entry.get("destination") in world.Content.ROUTES) and entry.get("kind") in ["postcard", "letter"] and entry.get("text") is String and entry.text.length() <= 500 and entry.get("read") is bool
