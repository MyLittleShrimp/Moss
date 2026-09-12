extends SceneTree
const World = preload("res://scripts/discovery_world.gd")
var count = 0
var failed = false
func check(value: bool, message: String) -> void:
	count += 1
	if not value: failed = true; push_error(message)
func _initialize() -> void:
	var world = World.new()
	world.release_timing = true
	world.rng.seed = 2
	world.data.foods.potato_box = 100
	var start = world.clock()
	check(world.command("travel", {"destination": "iceland", "food": "potato_box"}, start).ok, "departure")
	var end = world.data.trip_end
	var schedule = world.data.trip_snapshot.mail_schedule.duplicate(true)
	check(schedule.size() >= 1 and schedule.size() <= 4, "waypoint schedule")
	var previous = start
	for entry in schedule:
		check(entry.time > previous, "chronological intervals")
		check(entry.time < end, "sent before arrival")
		previous = entry.time
	check(world.valid_save(world.data), "schedule validates")
	var items = world.data.items.duplicate(true)
	var postcards = world.data.postcards.duplicate()
	var rare = world.data.trip_snapshot.rare
	check(not world.advance(schedule[0].time - 1), "no early arrival")
	check(world.data.travel_mail.is_empty(), "no early mail")
	check(not world.advance(schedule[0].time), "mail is not frog return")
	check(world.data.travel_mail.size() == 1 and not world.data.travel_mail[0].read, "mail delivered unread")
	check(world.data.items == items and world.data.postcards == postcards and world.data.trip_count == 0, "no economic or visit rewards")
	world.advance(schedule[0].time)
	check(world.data.travel_mail.size() == 1, "no duplicate polling")
	world.command("read_mail", {"id": schedule[0].id}, schedule[0].time)
	check(world.data.travel_mail[0].read, "read state")
	world.save_path = "res://artifacts/g11-mail-" + str(Time.get_ticks_usec()) + ".json"
	check(world.persist(), "save mail")
	var reloaded = World.new(world.save_path)
	check(reloaded.data.travel_mail.size() == 1 and reloaded.data.travel_mail[0].read, "restart read state")
	check(reloaded.data.trip_end == end and reloaded.data.trip_snapshot.rare == rare, "schedule does not reroll trip or loot")
	check(reloaded.advance(end + 1), "offline arrival")
	check(reloaded.data.travel_mail.size() == schedule.size(), "offline catchup all mail")
	check(reloaded.data.trip_count == 1, "only one return")
	var after = reloaded.data.items.duplicate(true)
	reloaded.advance(end + 2)
	check(reloaded.data.travel_mail.size() == schedule.size() and reloaded.data.items == after, "catchup idempotent")
	check(reloaded.valid_save(reloaded.data), "archive validates after arrival")
	var legacy = World.new()
	legacy.data = world.data.duplicate(true)
	legacy.data.erase("travel_mail")
	legacy.data.trip_snapshot.erase("mail_schedule")
	legacy.data.trip_snapshot.erase("mail_route_version")
	legacy.data.trip_snapshot.erase("mail_route")
	check(legacy.valid_save(legacy.data), "old schema7 accepted")
	legacy.advance(start + 2 * 86400)
	check(legacy.data.travel_mail.is_empty(), "no fabricated historical mail on upgrade")
	check(legacy.data.trip_snapshot.mail_schedule.is_empty() or legacy.data.trip_snapshot.mail_schedule[0].time > start + 2 * 86400, "upgrade schedules remaining journey")
	var bad = world.data.duplicate(true)
	bad.travel_mail.append(bad.travel_mail[0].duplicate(true))
	check(not world.valid_save(bad), "reject duplicate IDs")
	bad = world.data.duplicate(true)
	bad.trip_snapshot.mail_schedule[0].time = end + 1
	check(not world.valid_save(bad), "reject post-arrival schedule")
	var short_world = World.new()
	short_world.data.foods.herb_box = 2
	short_world.command("travel", {"destination": "creek", "food": "herb_box"}, start)
	check(short_world.data.trip_snapshot.mail_schedule.is_empty(), "short trips no mail spam")
	var demo = World.new()
	demo.data.pace = "demo"
	demo.data.foods.potato_box = 100
	demo.rng.seed = 2
	demo.command("travel", {"destination": "iceland", "food": "potato_box"}, start)
	check(demo.data.trip_snapshot.mail_schedule[0].time - start < (demo.data.trip_end - start), "demo correspondence follows accelerated journey")
	demo.data.trip_snapshot.erase("mail_schedule")
	demo.data.trip_snapshot.erase("mail_route_version")
	demo.data.trip_snapshot.incident = "forgot"
	demo.persist()
	check(demo.data.trip_snapshot.mail_schedule.is_empty(), "aborted trip has no mail")
	var nordic = []
	var saw_omission = false
	var saw_postcard = false
	var saw_letter = false
	for route in ["tokyo", "istanbul", "paris", "iceland"]:
		for seed_value in range(80):
			var trial = World.new()
			trial.release_timing = true
			trial.rng.seed = seed_value
			trial.data.foods.potato_box = 100
			trial.command("travel", {"destination": route, "food": "potato_box"}, start)
			var planned = trial.data.trip_snapshot.mail_route
			var mails = trial.data.trip_snapshot.mail_schedule
			check(trial.valid_save(trial.data), "route snapshot validation")
			var position = -1
			var cities = []
			for mail in mails:
				check(mail.destination not in cities, "one mail per waypoint per trip")
				check(planned.find(mail.destination) > position, "Shanghai before Dubai before Europe")
				cities.append(mail.destination)
				position = planned.find(mail.destination)
				saw_postcard = saw_postcard or mail.kind == "postcard"
				saw_letter = saw_letter or mail.kind == "letter"
			if planned.size() > mails.size(): saw_omission = true
			if planned.size() == 4 and planned[-1] not in nordic: nordic.append(planned[-1])
	check(saw_omission and saw_letter and saw_postcard, "random omissions and formats")
	check("stockholm" in nordic and "copenhagen" in nordic, "both Nordic variants")
	var library = preload("res://scripts/save_library.gd").new("res://artifacts/g11-transfer-" + str(Time.get_ticks_usec()))
	var export_path = library.directory + "/travel.json"
	check(library.export_save(world, export_path), "export partial mail state")
	var migrated_mail = library.import_save(export_path, "途中搬家")
	check(migrated_mail != null, "portable mail imports")
	if migrated_mail != null:
		var restored = migrated_mail.data.trip_snapshot.mail_schedule
		check(restored.size() == world.data.trip_snapshot.mail_schedule.size(), "portable schedule count")
		for i in range(restored.size()):
			check(restored[i].id == world.data.trip_snapshot.mail_schedule[i].id and absf(float(restored[i].time) - float(world.data.trip_snapshot.mail_schedule[i].time)) < 0.001 and restored[i].destination == world.data.trip_snapshot.mail_schedule[i].destination, "portable frozen identity time city")
	print("G11_MAIL_", "FAIL" if failed else "PASS", ": ", count)
	quit(1 if failed else 0)


