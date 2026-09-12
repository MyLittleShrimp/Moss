extends SceneTree
const World = preload("res://scripts/expanded_world.gd")
const OldWorld = preload("res://scripts/world.gd")
const C = preload("res://scripts/game_content.gd")
var checks = 0
var failed = false

func check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("FAIL: " + title)
		quit(1)
		assert(false, title)
	print("PASS: " + title)

func _initialize() -> void:
	var w = World.new()
	check(w.valid_save(w.data), "fresh v3 validates")
	for crop in C.CROPS:
		var start = w.clock()
		check(w.command("garden", {"plot": 0, "crop": crop}, start).ok, "plant " + crop)
		check(not w.command("garden", {"plot": 0}, start + 1).ok, "no early harvest " + crop)
		check(w.command("garden", {"plot": 0}, start + C.CROPS[crop].seconds + 1).ok and w.data.ingredients[crop] == C.CROPS[crop].yield, "timed yield " + crop)
	var empty = World.new()
	check(not empty.command("cook", {"food": "feast"}).ok and empty.data.meals == 0, "missing ingredient cannot partially consume")
	for id in C.CROPS: w.data.ingredients[id] = 20
	for food in C.FOODS:
		var before = w.data.ingredients.duplicate()
		check(w.command("cook", {"food": food}).ok and w.data.foods[food] == 1, "cook " + food)
		for id in C.FOODS[food].recipe: check(w.data.ingredients[id] == before[id] - C.FOODS[food].recipe[id], "exact ingredient debit " + food + id)
	w.data.foods.herb_box = 100
	check(not w.command("travel", {"destination": "istanbul"}).ok and w.data.foods.herb_box == 100, "food tier blocks remote trip without cost")
	check(C.portions("istanbul", "feast") == 4 and C.portions("tokyo", "mushroom_box") == 4, "rounded supply costs")
	var incidents = {}
	var rare_seen = false
	var duration_seen = {}
	for seed_value in range(160):
		var traveler = World.new()
		traveler.rng.seed = seed_value
		traveler.data.foods.feast = 4
		var start = traveler.clock()
		check_quiet(traveler.command("travel", {"destination": "istanbul", "food": "feast"}, start).ok, "departure")
		var snapshot = traveler.data.trip_snapshot.duplicate(true)
		incidents[snapshot.incident] = true
		duration_seen[int(traveler.data.trip_end - start)] = true
		check_quiet(traveler.data.foods.feast == 0, "exact four meals spent")
		check_quiet(not traveler.command("travel", {"destination": "creek"}, start).ok, "double departure denied")
		var end = traveler.data.trip_end
		traveler.command("pace", {"pace": "demo"}, start)
		check_quiet(traveler.data.trip_end == end and traveler.data.trip_snapshot == snapshot, "mode cannot reroll active trip")
		check_quiet(traveler.valid_save(traveler.data), "active snapshot validates")
		traveler.advance(end + 1)
		check_quiet(traveler.data.trip_count == 1 and traveler.data.letters.size() == 1, "settlement exactly once")
		if snapshot.incident == "forgot":
			check_quiet(traveler.data.postcards.is_empty() and traveler.data.items.is_empty() and traveler.data.foods.feast == 4, "aborted trip returns supplies but no false visit")
		else:
			check_quiet(traveler.data.items[snapshot.common] == 1 and traveler.data.postcards.size() == 1, "arrival common and postcard")
			if snapshot.rare != "": rare_seen = true
			if snapshot.incident == "friend": check_quiet(traveler.data.postcards[0] == "tokyo", "friend detours to safer shorter destination")
		if snapshot.incident == "ill":
			check_quiet(not traveler.command("care", {}, end + 1).ok, "soup needs herb")
			traveler.data.ingredients.herb = 1
			check_quiet(traveler.command("care", {}, end + 1).ok and traveler.data.ingredients.herb == 0, "soup cures with cost")
		if snapshot.incident == "mood": check_quiet(traveler.command("care", {}, end + 1).ok, "companionship restores mood")
		traveler.advance(end + 1000)
		check_quiet(traveler.data.trip_count == 1 and traveler.data.condition == "well", "no repeat grant and offline recovery")
	check(incidents.size() == 6 and rare_seen and duration_seen.size() > 100, "160 seeded trips cover all incidents, rares, varied timing")
	for destination in C.ROUTES:
		var traveler = World.new()
		traveler.rng.seed = 2
		var travel_food = "potato_box" if C.ROUTES[destination].tier > 3 else "feast"
		traveler.data.foods[travel_food] = 10
		var start = traveler.clock()
		check(traveler.command("travel", {"destination": destination, "food": travel_food}, start).ok, "route departure accepted " + destination)
		var duration = traveler.data.trip_end - start
		check(duration >= C.ROUTES[destination].min * 0.2 and duration <= C.ROUTES[destination].max * 1.3, "duration bounds " + destination)
		var active_path = "res://artifacts/g5-active-%s-%d.json" % [destination, Time.get_ticks_usec()]
		traveler.save_path = active_path
		traveler.persist()
		var reloaded = World.new(active_path)
		check(reloaded.warning.is_empty() and is_equal_approx(reloaded.data.trip_end, traveler.data.trip_end) and reloaded.data.trip_snapshot.rare == traveler.data.trip_snapshot.rare and reloaded.data.trip_snapshot.incident == traveler.data.trip_snapshot.incident, "reload freezes timing and reward " + destination)
		check(reloaded.data.active_event.text == traveler.data.active_event.text, "reload freezes narrative " + destination)
	w.give("stone")
	check(not w.command("sell", {"item": "stone"}).ok, "first keepsake cannot be sold")
	w.give("stone")
	var coins = w.data.coins
	check(w.command("sell", {"item": "stone"}).ok and w.data.coins == coins + 2 and "stone" in w.data.collected, "duplicates exchange, archive retained")
	check(w.command("buy", {"kind": "decor", "item": "plant"}).ok and "plant" in w.data.equipped, "purchase equips actual decor")
	check(not w.command("buy", {"kind": "decor", "item": "plant"}).ok, "no duplicate furniture charge")
	check(w.command("decorate", {"item": "plant"}).ok and "plant" not in w.data.equipped, "decoration removable")
	var price_before = w.data.coins
	check(not w.command("buy", {"kind": "food", "item": "feast"}).ok and w.data.coins == price_before, "insufficient coins has no debit")
	check(w.command("pace", {"pace": "demo"}).ok, "explicit demo mode")
	var now = w.clock()
	w.command("garden", {"plot": 1, "crop": "pumpkin"}, now, "once")
	check(w.data.plots[1] == now + 30 and not w.command("garden", {"plot": 1}, now + 31, "once").ok, "demo planting and idempotency")
	for version in [1, 2]:
		var old = OldWorld.new().fresh()
		old.schema = version
		old.herbs = 7
		old.meals = 3
		old.souvenirs = 2
		old.placed = true
		old.trip_end = Time.get_unix_time_from_system() + 600
		old.active_event = OldWorld.Catalog.choose("creek", [], true)
		if version == 1: old.erase("active_event"); old.erase("visited_event_ids")
		var copy = old.duplicate(true)
		var migrated = w.migrate(old)
		check(w.valid_save(migrated) and old == copy and migrated.ingredients.herb == 7 and migrated.foods.herb_box == 3 and migrated.items.stone == 2, "v%d migration preserves progress and source" % version)
		var path = "res://artifacts/g5-migration-%d-%d.json" % [version, Time.get_ticks_usec()]
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(old))
		file.close()
		var loaded = World.new(path)
		check(FileAccess.file_exists(path + ".v%d-backup" % version) and loaded.data.trip_end == old.trip_end, "backup and active trip survive v%d" % version)
		loaded.advance(loaded.data.trip_end + 1)
		check(loaded.data.items.stone == 3 and loaded.data.placed, "legacy pending reward preserves contract")
	var path = "res://artifacts/g5-reload-%d.json" % Time.get_ticks_usec()
	w.save_path = path
	w.persist()
	var loaded = World.new(path)
	check(loaded.data.ingredients.herb == w.data.ingredients.herb and loaded.data.ingredients.rice == w.data.ingredients.rice and loaded.data.equipped == w.data.equipped and loaded.warning.is_empty(), "new progression reload")
	loaded.persist()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var recovered = World.new(path)
	check(not recovered.warning.is_empty() and recovered.data.collected == w.data.collected, "corruption backup recovery")
	var bad = w.data.duplicate(true)
	bad.ingredients.rice = -1
	check(not w.valid_save(bad) and w.migrate({"schema": 2}) == null, "malformed state rejected")
	print("G5_WORLD_PASS: ", checks, " checks; in-memory and artifacts-only saves")
	quit(1 if failed else 0)

func check_quiet(value: bool, title: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error(title)
		quit(1)
		assert(false, title)
