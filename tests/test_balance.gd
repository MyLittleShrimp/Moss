extends SceneTree
const World = preload("res://scripts/discovery_world.gd")
const C = preload("res://scripts/game_content.gd")
var count = 0
var failed = false
func check(value: bool, note: String) -> void:
	count += 1
	if not value: failed = true; push_error(note)
func effort(id: String) -> float:
	var result = 0.0
	for crop in C.FOODS[id].recipe:
		result += float(World.Timing.CROPS[crop]) / C.CROPS[crop].yield * C.FOODS[id].recipe[crop]
	return result / C.FOODS[id].nutrition
func _initialize() -> void:
	check(is_equal_approx(effort("herb_box"), effort("rice_ball")), "tier1 equal growing efficiency")
	check(is_equal_approx(effort("mushroom_box"), effort("corn_ball")), "tier2 equal growing efficiency")
	check(effort("feast") / effort("veggie_box") < 1.25, "tier3 difference below 25 percent")
	var release = World.new()
	release.release_timing = true
	var dev = World.new()
	dev.data.pace = "balanced"
	for crop in C.CROPS:
		check(is_equal_approx(release.crop_seconds(crop), dev.crop_seconds(crop) * 60), "equal crop scaling")
	check(release.crop_seconds("strawberry") == 86400, "strawberry stays 24h")
	check(release.rare_chance("iceland", true) == 0.2, "snack gives +15pp")
	release.data.rare_misses.iceland = 7
	check(release.rare_chance("iceland", true) == 1.0, "snack probability capped")
	check(dev.rare_guarantee("tokyo") == 5 and dev.rare_guarantee("istanbul") == 4, "balanced pity uses release")
	check(C.food_price("berry_snack") > C.CROP_PRICES.strawberry, "snack cannot bypass costly berries")
	check(C.FOODS.corn_ball.recipe.corn == 4 and C.FOODS.veggie_box.recipe.carrot == 2, "rebalance ingredients")
	for crop in C.CROPS:
		var buyer = World.new()
		buyer.data.coins = C.CROP_PRICES[crop] - 1
		check(not buyer.command("buy", {"kind":"crop", "item":crop}).ok, "unaffordable has no debit")
		buyer.data.coins += 1
		check(buyer.command("buy", {"kind":"crop", "item":crop}).ok and buyer.data.coins == 0 and buyer.data.ingredients[crop] == 1, "actual material price")
	var start = release.clock()
	var aborts = 0
	var completed = 0
	for route in C.LONG_ROUTES:
		for seed_id in range(100):
			var a = World.new()
			var b = World.new()
			a.release_timing = true
			b.data.pace = "balanced"
			for w in [a, b]:
				w.rng.seed = seed_id
				w.data.foods.potato_box = 100
				w.data.foods.berry_snack = 1
				check(w.command("travel", {"destination":route,"food":"potato_box","snack":true}, start).ok, "depart")
				check(w.valid_save(JSON.parse_string(JSON.stringify(w.data))), "active JSON validates")
			check(absf((a.data.trip_end - start) - (b.data.trip_end - start) * 60) < 0.001, "equal trip scaling including incidents")
			check(a.data.trip_snapshot.rare == b.data.trip_snapshot.rare, "same reward roll")
			var end = float(a.data.trip_end)
			if a.data.trip_snapshot.incident == "forgot":
				aborts += 1
				check(end - start >= 3600 and end - start <= 57600, "long abort within 1-16h")
				a.advance(end)
				check(a.data.foods.potato_box == 100 and a.data.foods.berry_snack == 1, "abort refunds all")
				check(a.data.travel_progress.is_empty() and a.data.coins == 10, "no false progress for abort")
				check(a.data.letters[0].text.contains("小故事"), "abort story")
			else:
				completed += 1
				var schedule = a.data.trip_snapshot.mail_schedule.duplicate(true)
				check(not schedule.is_empty(), "long journey always receives mail")
				var previous = start
				for mail in schedule:
					check(mail.time > previous and mail.time - previous <= 172800.001, "ordered mail max silence 48h")
					previous = mail.time
				check(end - previous <= 172800.001, "last silence bounded too")
				# Version 2 upgrades keep all scheduled waypoint identities and times.
				var old = a.data.duplicate(true)
				old.trip_snapshot.mail_route_version = 2
				a.data = old
				a.persist()
				check(a.data.trip_snapshot.mail_schedule == schedule, "existing schedule not rerolled")
				var detoured = a.data.trip_snapshot.incident == "friend"
				a.advance(end + 1)
				if detoured: check(a.data.letters[0].text.contains("改道小记"), "detour does not invent planned-city experiences")
				check(a.data.travel_progress.get(route, 0) == 1, "every completed long itinerary earns page")
				check(a.data.coins == 10 + C.PROGRESS_COINS[route], "page reward")
				var state = JSON.stringify(a.data)
				a.advance(end + 1)
				check(JSON.stringify(a.data) == state, "repeated settlement does not duplicate progress")
				check(a.valid_save(a.data), "settled save validates")
	var legacy = World.new()
	legacy.data.erase("travel_progress")
	check(legacy.valid_save(legacy.data), "old schema7 missing optional progress accepts")
	legacy.advance(start)
	check(legacy.data.travel_progress.is_empty(), "old save initializes empty progress without invented past pages")
	var invalid = legacy.data.duplicate(true)
	invalid.travel_progress = {"iceland": -1}
	check(not legacy.valid_save(invalid), "negative progress rejects")
	check(aborts > 0 and completed > 0, "both paths exercised")
	# Completed album milestone and portable saves, separate fixture directory.
	var w = World.new()
	w.data.pace = "balanced"
	w.data.travel_progress.iceland = 2
	w.data.foods.potato_box = 100
	w.rng.seed = 2
	w.command("travel", {"destination":"iceland","food":"potato_box"}, start)
	w.advance(w.data.trip_end + 1)
	check(w.data.travel_progress.iceland == 3 and w.data.coins == 26, "third page adds album bonus")
	w.save_path = "res://artifacts/g17-balance-save.json"
	check(w.persist(), "save progress")
	var loaded = World.new(w.save_path)
	check(int(loaded.data.travel_progress.get("iceland", 0)) == 3 and loaded.data.pace == "balanced", "load progress and pace")
	print("G17_BALANCE_", "FAIL" if failed else "PASS", ": ", count, " checks; ", aborts, " aborted, ", completed, " completed")
	quit(1 if failed else 0)
