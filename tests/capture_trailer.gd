extends "res://scripts/main.gd"
## Promotional fixture: real UI, isolated inventory, no player configuration or HTTP.
var trailer_start := 0
func hold_until(seconds: float) -> void:
	while Engine.get_process_frames() - trailer_start < int(seconds * 30):
		await get_tree().process_frame

func qa_flow() -> void:
	assert(world.save_path.is_empty() and not ai_client.enabled)
	trailer_start = Engine.get_process_frames()
	world.release_timing = true
	for id in Content.CROPS: world.data.ingredients[id] = 8
	world.sync_aliases()
	refresh()
	await hold_until(4)
	life_panel.open("田园")
	await hold_until(5)
	await qa_click(life_panel.actions.seed_herb)
	await qa_click(life_panel.actions.plot0)
	await hold_until(6.5)
	# Cut across growing time; caption explicitly marks accelerated demonstration.
	world.data.plots[0] = world.clock() - 1
	life_panel.rebuild()
	await hold_until(7.5)
	await qa_click(life_panel.actions.plot0)
	await hold_until(9)
	life_panel.open("厨房")
	await hold_until(10.5)
	await qa_click(life_panel.actions.herb_box)
	await hold_until(12)
	await qa_click(life_panel.actions.rice_ball)
	await hold_until(14)
	world.data.foods.potato_box = 8
	life_panel.open("远行")
	await qa_click(life_panel.actions.route_iceland)
	await hold_until(15.5)
	await qa_click(life_panel.actions.food_potato_box)
	await hold_until(17)
	# Select a reproducible journey with a Shanghai postcard, using game rules.
	for seed_value in range(200):
		var candidate = World.new()
		candidate.release_timing = true
		candidate.rng.seed = seed_value
		candidate.data.foods.potato_box = 8
		candidate.data.rare_misses.iceland = 2
		candidate.command("travel", {"destination": "iceland", "food": "potato_box"})
		var schedule = candidate.data.trip_snapshot.get("mail_schedule", [])
		if schedule.size() > 0 and schedule[0].kind == "postcard" and schedule[0].destination == "shanghai":
			world.rng.seed = seed_value
			world.data.rare_misses.iceland = 2
			break
	await qa_click(life_panel.actions.travel)
	assert(world.data.trip_end > 0)
	life_panel.hide()
	await hold_until(19)
	var letters = world.data.trip_snapshot.mail_schedule
	world.advance(letters[0].time)
	postcard_view.open_mail(world.data.travel_mail[0])
	await hold_until(25)
	postcard_view.hide()
	world.advance(world.data.trip_end + 1)
	refresh()
	parcel_view.open()
	await hold_until(26)
	await qa_click(parcel_view.open_button)
	await hold_until(28)
	if not world.data.pending_discoveries.is_empty(): await qa_click(parcel_view.open_button)
	await hold_until(31)
	parcel_view.hide()
	assert(world.outfit_unlocked("aurora"))
	assert(world.command("wear", {"item": "aurora"}).ok)
	refresh()
	await hold_until(35)
	home_interactions.open_book(0)
	await hold_until(37)
	home_interactions.open_book(1)
	await hold_until(39)
	home_interactions.book_panel.hide()
	settings_panel.open()
	assert(settings_panel.key.text.is_empty())
	await hold_until(43)
	settings_panel.hide()
	await hold_until(47)
	print("TRAILER_CAPTURE_PASS: 47 seconds; real UI; memory-only fixture; no credentials or LLM requests")
	get_tree().quit()
