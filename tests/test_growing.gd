extends SceneTree
const World = preload("res://scripts/growing_world.gd")
var checks = 0
func check(value: bool, title: String) -> void:
	checks += 1
	if not value:
		push_error(title)
		quit(1)
		assert(value, title)
func _initialize() -> void:
	var w = World.new()
	check(w.valid_save(w.data), "fresh schema5")
	for script in ["world", "expanded_world", "living_world"]:
		var old = load("res://scripts/" + script + ".gd").new()
		old.data.rain_preference = "like"
		old.data.memory_source = "我喜欢雨声"
		var migrated = w.migrate(old.data)
		check(w.valid_save(migrated), "migration " + script)
		check(migrated.preferences.has("雨声") and migrated.coins == 10, "legacy preference preserved")
		var path = "res://artifacts/g7-migrate-" + script + ".json"
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(old.data))
		file.close()
		var loaded = World.new(path)
		check(loaded.valid_save(loaded.data) and loaded.data.preferences.has("雨声"), "disk migration " + script)
		check(FileAccess.file_exists(path + ".v%d-backup" % int(old.data.schema)), "migration backup " + script)
	check(w.accept_memory_text("我喜欢茉莉花").handled, "generic preference")
	check(w.accept_memory_text("我不喜欢茉莉花").handled and w.data.preferences["茉莉花"].value == "dislike", "correction")
	check(not w.accept_memory_text("我朋友喜欢猫").handled, "friend not player")
	check(not w.accept_memory_text("我喜欢猫吗？").handled, "question not assertion")
	w.command("preference_remove", {"topic": "茉莉花"})
	check(w.data.preferences.is_empty(), "forget")
	w.command("garden", {"plot": 0, "crop": "rice"})
	w.data.plots[0] = w.clock() - 1
	w.command("garden", {"plot": 0})
	check(w.data.habits.crops.rice == 1 and w.data.preferences.is_empty(), "harvest observation not preference")
	var day = w.today()
	w.ensure_book(day)
	var book = w.data.daily_book.duplicate(true)
	w.ensure_book(day)
	check(book == w.data.daily_book, "same day cached")
	check(w.begin_book_attempt() and not w.begin_book_attempt(), "one attempt")
	var before = [w.data.coins, w.data.ingredients.duplicate(), w.data.foods.duplicate()]
	var epoch = w.data.memory_epoch
	w.command("preference_set", {"topic": "猫"})
	check(not w.finish_book(day, epoch, "旧回复"), "forgotten context rejected")
	check(w.finish_book(day, w.data.memory_epoch, "一只蜗牛迷了路。\n\n它在茶摊遇见了风。\n\n回家的路上，多了一位朋友。"), "validated three page story")
	check(w.data.daily_book.source == "llm" and w.data.daily_book.pages.size() == 3, "source and pages")
	check(before == [w.data.coins, w.data.ingredients, w.data.foods], "story cannot reward")
	w.command("read_book", {"page": 1})
	w.command("read_book", {"page": 2})
	check(w.data.habits.reading_days.size() == 1, "read count once daily")
	check(w.valid_save(JSON.parse_string(JSON.stringify(w.data))), "json round trip")
	var saved = FileAccess.open("res://artifacts/g7-cache.json", FileAccess.WRITE)
	saved.store_string(JSON.stringify(w.data))
	saved.close()
	var reopened = World.new("res://artifacts/g7-cache.json")
	check(reopened.data.daily_book.source == "llm" and reopened.data.preferences.has("猫"), "book and preferences survive reopen")
	w.ensure_book(w.today(w.clock() + 86400))
	check(w.data.daily_book.day != day and not w.data.daily_book.attempted, "next day refresh")
	check(not w.finish_book(day, w.data.memory_epoch, "迟到"), "cross day stale reply")
	w.command("clear_observations")
	check(w.observations().is_empty() and w.data.preferences.has("猫"), "independent forget")
	print("G7_WORLD_PASS: ", checks)
	quit()
