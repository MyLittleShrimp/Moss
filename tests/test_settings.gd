extends SceneTree
const World = preload("res://scripts/discovery_world.gd")
const Library = preload("res://scripts/save_library.gd")
const Client = preload("res://scripts/player_ai.gd")
var checks = 0
var failed = false

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failed = true; push_error(message)

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var directory = "res://artifacts/g10-test-" + str(Time.get_ticks_usec())
	var library = Library.new(directory)
	var first = library.create("第一间")
	check(first != null, "create")
	var original_id = library.active
	first.data.ingredients.herb = 19
	first.command("garden", {"plot": 0, "crop": "herb"})
	check(first.persist(), "autosave")
	var clone = library.create("副本", first.data)
	check(clone.data.ingredients.herb == 19, "copy inventory")
	clone.data.ingredients.herb = 1
	clone.persist()
	var loaded = library.load_slot(original_id)
	check(loaded.data.ingredients.herb == 19, "isolated slots")
	var destination = directory + "/portable.json"
	check(library.export_save(loaded, destination), "portable export")
	check(not library.export_save(loaded, destination), "no silent overwrite")
	var second_machine = Library.new(directory + "/other-device")
	var imported = second_machine.import_save(destination, "新设备")
	check(imported != null and imported.data.ingredients.herb == 19, "portable import")
	check(imported.data.plots == loaded.data.plots, "timers preserved")
	var bad = FileAccess.open(directory + "/bad.json", FileAccess.WRITE)
	bad.store_string("{bad"); bad.close()
	var active_before = second_machine.active
	check(second_machine.import_save(directory + "/bad.json", "损坏") == null, "reject corrupt")
	check(second_machine.active == active_before, "invalid import keeps active")
	check(second_machine.load_slot("../escape") == null, "path traversal")
	var fresh = second_machine.create("新生活")
	check(fresh.data.ingredients.herb == 0, "new game")
	var restart = Library.new(directory + "/other-device")
	check(restart.active == second_machine.active, "active survives restart")
	var legacy = World.new(directory + "/legacy.json")
	legacy.data.ingredients.rice = 7
	legacy.persist()
	var bytes_before = FileAccess.get_file_as_bytes(legacy.save_path)
	var migration = Library.new(directory + "/migration")
	var migrated = migration.initial(legacy.save_path)
	check(migrated.data.ingredients.rice == 7, "legacy copy")
	check(bytes_before == FileAccess.get_file_as_bytes(legacy.save_path), "legacy source untouched")
	var world = World.new()
	world.release_timing = true
	check(world.crop_seconds("strawberry") == 86400 and world.crop_seconds("herb") == 300, "release crops")
	check(world.Timing.duration_text(86400) == "1 天", "duration display")
	world.data.rare_misses.iceland = 2
	check(world.roll_rare("iceland") == "auroraglass", "release far-travel three visit guarantee")
	check(world.rare_guarantee("creek") == 8, "short routes keep eight visit guarantee")
	check(not world.command("pace", {"pace": "demo"}).ok, "release denies acceleration")
	world.data.pace = "demo"
	check(world.crop_seconds("strawberry") == 86400, "import demo cannot accelerate release")
	for route in world.Content.ROUTES:
		for seed_value in range(15):
			var trip_world = World.new()
			trip_world.release_timing = true
			trip_world.rng.seed = seed_value
			trip_world.data.foods.potato_box = 100
			var now = trip_world.clock()
			check(trip_world.command("travel", {"destination": route, "food": "potato_box"}, now).ok, "release departure")
			var duration = trip_world.data.trip_end - now
			check(duration > 0 and duration <= trip_world.trip_bounds(route)[1], "release cap including incident")
			if route == "iceland" and trip_world.data.trip_snapshot.incident != "forgot": check(duration >= 604800, "iceland seven days")
	var ai = Client.new()
	root.add_child(ai)
	ai.config_path = directory + "/ai.cfg"
	ai.secret_path = directory + "/key.enc"
	check(ai.endpoint.is_empty() and ai.api_key.is_empty(), "no built-in provider")
	check(ai.validation("http://127.0.0.1:11434/v1/chat/completions", "local-model").is_empty(), "ollama endpoint")
	check(not ai.validation("http://remote.example/v1/chat/completions", "model").is_empty(), "reject plaintext cloud")
	check(not ai.validation("https://name:secret@example.com/v1/chat/completions", "model").is_empty(), "no url credentials")
	check(ai.configure("https://example.com/v1/chat/completions", "model", "TEST_ONLY_NOT_A_REAL_KEY", true, "test-password-only").is_empty(), "encrypted save")
	check(not "TEST_ONLY_NOT_A_REAL_KEY" in FileAccess.get_file_as_string(ai.config_path), "no plaintext key in settings")
	var after_restart = Client.new()
	root.add_child(after_restart)
	after_restart.config_path = ai.config_path
	after_restart.secret_path = ai.secret_path
	after_restart.load_settings()
	check(after_restart.api_key.is_empty() and not after_restart.enabled, "restart locked and off")
	check(after_restart.unlock("test-password-only"), "unlock encrypted key")
	check(after_restart.api_key == "TEST_ONLY_NOT_A_REAL_KEY", "correct key roundtrip")
	check(ai.configure("http://127.0.0.1:11434/v1/chat/completions", "local-model", "").is_empty(), "keyless local")
	check(not FileAccess.file_exists(ai.secret_path), "session-only clears old encrypted key")
	check(ai.parse_response({"choices": [{"finish_reason": "stop", "message": {"content": '{"utterance":"测试问候","emotion":"calm"}'}}]}).ok, "valid structured response")
	check(not ai.parse_response({"choices": [{"finish_reason": "stop", "message": {"content": '{"utterance":"奖励","emotion":"calm","grant":100}'}}]}).ok, "reject extra actions")
	check(not "TEST_ONLY_NOT_A_REAL_KEY" in FileAccess.get_file_as_string(destination), "portable save excludes key")
	ai.queue_free(); after_restart.queue_free()
	print("G10_RULES_", "FAIL" if failed else "PASS", ": ", checks, " checks; artifacts-only, no player credentials")
	quit(1 if failed else 0)
