extends SceneTree

const World = preload("res://scripts/world.gd")
const Dialogue = preload("res://scripts/local_dialogue.gd")
var checks = 0

func check(condition: bool, title: String) -> void:
	checks += 1
	if not condition:
		push_error("FAIL: " + title)
		quit(1)
		assert(false, title)
	print("PASS: " + title)

func _initialize() -> void:
	var world = World.new()
	check(not world.command("cook", {}, 100).ok, "cannot cook without ingredients")
	check(not world.command("garden", {"plot": 10}, 100).ok, "reject invalid plot")
	check(world.command("garden", {"plot": 0}, 100, "plant-1").ok, "plant")
	check(not world.command("garden", {"plot": 0}, 120, "plant-1").ok, "duplicate key cannot harvest")
	check(world.command("garden", {"plot": 0}, 120).ok and world.data.herbs == 1, "mature harvest")
	check(world.command("cook", {}, 120).ok and world.data.herbs == 0 and world.data.meals == 1, "cook conserves inventory")
	var dialogue = Dialogue.new()
	dialogue.respond("我朋友喜欢雨声", world)
	check(world.data.rain_preference == "unknown", "friend preference not attributed to player")
	dialogue.respond("我喜欢雨声", world)
	check(world.data.rain_preference == "like", "store explicit preference")
	var now = world.clock()
	check(world.command("travel", {}, now).ok, "travel starts")
	check(not world.command("travel", {}, now).ok, "cannot travel twice")
	var end = float(world.data.trip_end)
	check(world.advance(end + 1) and world.data.souvenirs == 1, "offline return grants once")
	world.advance(end + 500)
	check(world.data.souvenirs == 1, "repeated settlement grants nothing")
	check("雨" in world.data.letters[0].text, "letter uses departure memory snapshot")
	check(world.command("place", {}, end + 500).ok, "place souvenir")
	check(not world.command("place", {}, end + 500).ok, "cannot place duplicate")
	dialogue.respond("我不喜欢雨声", world)
	check(world.data.rain_preference == "dislike", "correction supersedes preference")
	dialogue.respond("忘记雨声偏好", world)
	check(world.data.rain_preference == "unknown" and world.data.memory_source == "", "forget removes preference source")
	check(not world.command("set_coins", {}, end + 500).ok, "unknown action rejected")
	var path = "res://artifacts/test-save.json"
	world.save_path = path
	check(world.persist(), "save succeeds")
	var loaded = World.new(path)
	check(loaded.data.placed and loaded.data.souvenirs == 1, "reload preserves progression")
	check(loaded.persist(), "second save creates backup")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var recovered = World.new(path)
	check(recovered.data.placed and not recovered.warning.is_empty(), "corrupt save recovered from backup")
	var malformed = world.data.duplicate(true)
	malformed.plots = ["oops", 0, 0]
	check(not world.valid_save(malformed), "reject malformed schema")
	var legacy = world.data.duplicate(true)
	legacy.schema = 1
	legacy.erase("active_event")
	legacy.erase("visited_event_ids")
	var upgraded = world.migrate(legacy)
	check(world.valid_save(upgraded) and upgraded.souvenirs == 1 and upgraded.placed, "v1 migration retains collection")
	check(legacy.schema == 1 and not legacy.has("active_event"), "migration does not mutate source")
	legacy.trip_end = world.clock() + 30
	legacy.trip_rain = true
	upgraded = world.migrate(legacy)
	check(upgraded.active_event.id == "creek_rain" and upgraded.trip_end == legacy.trip_end, "migration retains pending trip time and preference")
	var legacy_path = "res://artifacts/migration-" + str(Time.get_ticks_usec()) + ".json"
	var legacy_file = FileAccess.open(legacy_path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	var migrated_file = World.new(legacy_path)
	check(FileAccess.file_exists(legacy_path + ".v1-backup"), "loading legacy save preserves original file backup")
	check(migrated_file.data.schema == 2 and migrated_file.persist(), "migrated save writes v2")
	var reloaded_file = World.new(legacy_path)
	check(reloaded_file.data.active_event.id == "creek_rain" and reloaded_file.data.souvenirs == 1, "reloading migration keeps active snapshot and rewards")
	var traveler = World.new()
	traveler.data.meals = 10
	check(not traveler.command("travel", {"destination": "invalid"}).ok and traveler.data.meals == 10, "invalid destination cannot consume meal")
	for destination in ["creek", "market", "hill"]:
		var ids = []
		for index in range(2):
			traveler.command("travel", {"destination": destination})
			var selected = traveler.data.active_event.duplicate(true)
			traveler.data.rain_preference = "dislike"
			traveler.advance(float(traveler.data.trip_end) + 1)
			check(traveler.data.letters[0].event_id == selected.id, "event frozen at departure " + selected.id)
			ids.append(selected.id)
		check(ids[0] != ids[1], "prefer unseen event " + destination)
	check(traveler.data.letters.size() == 6 and traveler.data.souvenirs == 6, "six trips retain six letters and rewards")
	check(not traveler.valid_save({"schema": 99}), "unknown save schema rejected")
	print("WORLD_TESTS_PASS: ", checks)
	quit(0)
