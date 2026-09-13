extends SceneTree
const World = preload("res://scripts/living_world.gd")
const G5 = preload("res://scripts/expanded_world.gd")
const G1 = preload("res://scripts/world.gd")
var checks = 0
var failed = false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failed = true
		push_error("FAIL: " + message)
	else: print("PASS: " + message)

func _initialize() -> void:
	var world = World.new()
	check(world.valid_save(world.data), "fresh schema4 valid")
	check(not world.command("plant_move", {"item": "desk"}, 100).ok, "cannot move unowned pot")
	check(world.command("buy", {"kind": "decor", "item": "plant"}, 100).ok, "existing plant purchase integrates")
	for id in World.SPOTS:
		check(world.command("plant_move", {"item": id}, 100).ok and world.data.plant_spot == id, "move pot " + id)
	check(not world.command("plant_move", {"item": "outside"}, 100).ok, "reject outside placement")
	world.data.coins = 60
	check(world.command("home_buy", {"kind": "plant", "item": "flower"}, 100, "flower").ok and world.data.coins == 48 and world.data.plant_style == "flower", "flower purchase has exact debit and equips")
	check(not world.command("home_buy", {"kind": "plant", "item": "flower"}, 100, "flower").ok and world.data.coins == 48, "duplicate purchase key cannot charge")
	check(world.command("plant_style", {"item": "leaf"}, 100).ok and world.data.plant_style == "leaf", "switch back to owned plant")
	check(world.command("rug", {"item": "meadow"}, 100).ok and world.data.coins == 48, "starter rug free to equip")
	check(world.command("rug", {"item": "woven"}, 100).ok, "switch rug back")
	check(world.command("rug", {"item": "sunset"}, 100).ok, "second starter rug available")
	world.data.coins = 0
	check(not world.command("home_buy", {"kind": "rug", "item": "sunset"}, 100).ok and world.data.coins == 0, "insufficient balance untouched")
	check(world.command("read_book", {"page": 2}, 100).ok and world.data.book_page == 2, "book page persisted")
	check(not world.command("read_book", {"page": 3}, 100).ok, "book page bounds")
	world.data.cleanliness = 45
	check(world.command("sweep", {}, 100).ok and world.data.cleanliness == 70, "sweep cleans")
	check(not world.command("sweep", {}, 101).ok and world.data.cleanliness == 70, "sweep animation cooldown")
	check(world.command("sweep", {}, 103).ok and world.data.coins == 0, "sweeping has no money reward")
	world.advance(100000)
	check(world.data.cleanliness >= 40 and world.data.condition == "well", "offline dust never causes illness or loss")
	var kinds = {}
	for i in range(100):
		var weather = World.weather_at(1800 * i + 1)
		kinds[weather.kind] = true
		check(weather == World.weather_at(1800 * i + 500) and weather.humidity >= 42 and weather.humidity <= 92, "weather stable and humidity bounded " + str(i))
	check(kinds.size() == 3, "all three weather kinds covered")
	for version in [1, 2, 3]:
		var old = G5.new().fresh() if version == 3 else G1.new().fresh()
		old.schema = version
		if version == 1: old.erase("active_event"); old.erase("visited_event_ids")
		old.herbs = 5
		old.meals = 2
		old.souvenirs = 3
		if version == 3:
			old.ingredients.herb = 5
			old.foods.herb_box = 2
			old.items.stone = 3
		var path = "res://artifacts/g6-v%d-%d.json" % [version, Time.get_ticks_usec()]
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(old))
		file.close()
		var loaded = World.new(path)
		check(loaded.warning.is_empty() and loaded.data.schema == 4 and loaded.data.ingredients.herb == 5 and loaded.data.items.stone == 3, "v%d upgrade preserves progress" % version)
		check(FileAccess.file_exists(path + ".v%d-backup" % version), "v%d backup exists" % version)
	world.save_path = "res://artifacts/g6-state-%d.json" % Time.get_ticks_usec()
	world.command("plant_style", {"item": "flower"})
	world.command("rug", {"item": "meadow"})
	world.persist()
	var loaded = World.new(world.save_path)
	check(loaded.warning.is_empty() and loaded.data.plant_spot == world.data.plant_spot and loaded.data.rug == "meadow" and loaded.data.plant_style == "flower" and loaded.data.book_page == 2, "decor and reading survive reload")
	var bad = world.data.duplicate(true)
	bad.plant_spot = "invalid"
	check(not world.valid_save(bad), "invalid furniture slot rejected")
	bad = world.data.duplicate(true)
	bad.weather.humidity = -5
	check(not world.valid_save(bad), "invalid humidity rejected")
	var prior = G5.new()
	prior.data.foods.feast = 4
	prior.rng.seed = 2
	prior.command("travel", {"destination": "istanbul", "food": "feast"})
	var upgraded = world.migrate(prior.data)
	check(upgraded.trip_end == prior.data.trip_end and upgraded.trip_snapshot == prior.data.trip_snapshot, "active travel outcome unchanged by migration")
	world.data = upgraded
	world.advance(world.data.trip_end + 1)
	check(world.data.trip_count == 1 and world.data.letters.size() == 1, "travel settlement works in schema4")
	print("G6_RULES_", "FAIL" if failed else "PASS", ": ", checks)
	quit(1 if failed else 0)
