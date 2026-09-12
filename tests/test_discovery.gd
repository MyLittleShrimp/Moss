extends SceneTree
const World = preload("res://scripts/discovery_world.gd")
const Content = preload("res://scripts/game_content.gd")
var checks = 0
var failed = false
func check(ok: bool, title: String) -> void:
	checks += 1
	if not ok: failed = true; push_error("FAIL: " + title)
func _initialize() -> void:
	var w = World.new()
	check(w.valid_save(w.data), "fresh schema7")
	check(Content.CROPS.size() == 8 and Content.FOODS.size() == 8 and Content.ROUTES.size() == 9 and Content.ITEMS.size() == 18, "catalog sizes")
	for crop in ["corn", "carrot", "potato", "strawberry"]:
		check(w.command("garden", {"plot": 0, "crop": crop}, 100).ok, "plant " + crop)
		var end = w.data.plots[0]
		check(not w.command("garden", {"plot": 0}, end - 1).ok, "not ripe")
		check(w.command("garden", {"plot": 0}, end + 1).ok and w.data.ingredients[crop] == Content.CROPS[crop].yield, "harvest " + crop)
	for crop in Content.CROPS: w.data.ingredients[crop] = 20
	for food in ["corn_ball", "veggie_box", "potato_box", "berry_snack"]: check(w.command("cook", {"food": food}).ok, "cook " + food)
	check(not w.command("travel", {"destination": "creek", "food": "berry_snack"}).ok, "snack not main food")
	w.data.foods.berry_snack = 0
	var foods = w.data.foods.duplicate()
	check(not w.command("travel", {"destination": "dali", "food": "potato_box", "snack": true}).ok and w.data.foods == foods, "missing snack atomic reject")
	for destination in Content.ROUTES:
		var t = World.new()
		t.data.foods.potato_box = 100
		t.data.foods.berry_snack = 1
		t.data.rare_misses[destination] = 7
		t.rng.seed = 2
		check(t.command("travel", {"destination": destination, "food": "potato_box", "snack": true}, 100).ok, "depart " + destination)
		check(t.data.foods.berry_snack == 0, "snack consumed exactly one")
		var actual = t.data.active_event.destination
		if actual == destination: check(t.data.trip_snapshot.rare == Content.ROUTES[destination].rare, "pity guaranteed before departure snapshot")
		var snapshot = t.data.trip_snapshot.duplicate(true)
		var file = FileAccess.open("res://artifacts/g9-trip-" + destination + ".json", FileAccess.WRITE)
		file.store_string(JSON.stringify(t.data)); file.close()
		# Inspect a direct JSON roundtrip without advancing historical test clock on load.
		var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://artifacts/g9-trip-" + destination + ".json"))
		check(t.valid_save(parsed) and parsed.trip_snapshot.rare == snapshot.rare, "snapshot JSON valid")
		t.advance(t.data.trip_end + 1)
		if snapshot.incident != "forgot":
			check(not t.data.pending_discoveries.is_empty() and not t.discovered(Content.ROUTES[actual].common), "arrival wrapped")
			check(not Content.ITEMS[Content.ROUTES[actual].common].name in t.data.letters[0].rewards, "letter does not spoil")
			var count = t.data.items.duplicate()
			while not t.data.pending_discoveries.is_empty(): check(t.command("reveal_next").ok, "reveal")
			check(t.data.items == count, "reveal never grants twice")
			check(t.postcard_content(actual).title == Content.ROUTES[actual].name, "new postcard")
	var hidden = World.new()
	hidden.give("cloudshawl")
	check(not hidden.outfit_unlocked("shawl") and not hidden.command("wear", {"item": "shawl"}).ok, "unopened outfit locked")
	check(hidden.command("reveal_next", {}, -1, "open1").ok and hidden.outfit_unlocked("shawl"), "revealed outfit unlocks")
	hidden.give("iris")
	check(not hidden.command("reveal_next", {}, -1, "open1").ok and hidden.data.pending_discoveries.size() == 1, "duplicate reveal id rejected")
	for item in ["tiedye", "coffeecup", "basalt"]:
		hidden.give(item)
		while not hidden.data.pending_discoveries.is_empty(): hidden.command("reveal_next")
		check(hidden.command("claim_room_reward", {"item": item}).ok, "new room gift")
	check(not hidden.command("buy", {"kind": "decor", "item": "tiecloth"}).ok, "reward not purchasable")
	var old = load("res://scripts/reward_world.gd").new()
	old.data.ingredients.herb = 6
	old.data.preferences["花"] = {"value": "like", "source": "测试", "updated": 1}
	old.give("silk")
	for id in ["corn", "carrot", "potato", "strawberry"]: old.data.ingredients.erase(id)
	for id in ["corn_ball", "veggie_box", "potato_box", "berry_snack"]: old.data.foods.erase(id)
	var file = FileAccess.open("res://artifacts/g9-v6.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(old.data)); file.close()
	var migrated = World.new("res://artifacts/g9-v6.json")
	check(migrated.valid_save(migrated.data) and migrated.data.ingredients.herb == 6 and migrated.data.preferences.has("花"), "v6 preserves progress")
	check(migrated.outfit_unlocked("scarf") and migrated.data.pending_discoveries.is_empty(), "old collections remain discovered")
	check(FileAccess.file_exists("res://artifacts/g9-v6.json.v6-backup"), "v6 backup")
	var broken = migrated.data.duplicate(true)
	broken.ingredients.erase("rice")
	check(not migrated.valid_save(broken), "missing old crop rejected")
	var folded = World.new()
	folded.data.foods.herb_box = 1
	folded.data.foods.berry_snack = 1
	folded.data.rare_misses.creek = 4
	folded.command("travel", {"destination": "creek", "food": "herb_box", "snack": true}, 100)
	folded.data.trip_snapshot.incident = "forgot"
	folded.advance(folded.data.trip_end + 1)
	check(folded.data.foods.herb_box == 1 and folded.data.foods.berry_snack == 1, "folded trip refunds snack and main")
	check(folded.data.rare_misses.creek == 4 and folded.data.pending_discoveries.is_empty(), "folded trip no pity or discoveries")
	var counter = World.new()
	counter.data.foods.herb_box = 20
	for i in range(7):
		counter.data.condition = "well"
		counter.command("travel", {"destination": "creek"}, counter.clock())
		counter.data.trip_snapshot.incident = "ordinary"
		counter.data.trip_snapshot.rare = ""
		counter.advance(counter.data.trip_end + 1)
		check(counter.data.rare_misses.creek == i + 1, "miss counted only at arrival")
	check(counter.roll_rare("creek") == "glowstone", "eighth arrival guaranteed")
	counter.command("travel", {"destination": "creek"})
	counter.data.trip_snapshot.incident = "ordinary"
	counter.advance(counter.data.trip_end + 1)
	check(counter.data.rare_misses.creek == 0, "rare discovery resets pity")
	file = FileAccess.open("res://artifacts/g9-unopened.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(counter.data)); file.close()
	var reopened = World.new("res://artifacts/g9-unopened.json")
	check(reopened.data.pending_discoveries == counter.data.pending_discoveries and not reopened.discovered("glowstone"), "unopened survives restart")
	check(reopened.data.rare_misses.creek == 0, "pity survives restart")
	var ice = World.new()
	ice.data.foods.feast = 20
	var original_foods = ice.data.foods.duplicate()
	check(not ice.command("travel", {"destination": "iceland", "food": "feast"}).ok and ice.data.foods == original_foods, "ice needs tier4 no partial debit")
	for version in [1, 2, 3, 4, 5]:
		var script = {1: "world", 2: "world", 3: "expanded_world", 4: "living_world", 5: "growing_world"}[version]
		var legacy = load("res://scripts/" + script + ".gd").new().data
		legacy.schema = version
		var converted = w.migrate(legacy)
		check(w.valid_save(converted) and converted.schema == 7, "old schema migration " + str(version))
	print("G9_RULES_PASS: ", checks, " checks" if not failed else " FAILED")
	quit(1 if failed else 0)
