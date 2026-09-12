extends "res://scripts/main.gd"
func qa_flow() -> void:
	for seed_value in range(200):
		world = World.new()
		world.release_timing = true
		world.rng.seed = seed_value
		world.data.foods.potato_box = 100
		world.command("travel", {"destination": "iceland", "food": "potato_box"})
		var choices = world.data.trip_snapshot.mail_schedule
		if choices.any(func(e): return e.kind == "postcard") and choices.any(func(e): return e.kind == "letter"): break
	var schedule = world.data.trip_snapshot.mail_schedule.duplicate(true)
	assert(schedule.size() >= 2)
	world.advance(schedule[-1].time)
	life_panel.open("信箱")
	await capture("artifacts/g11-mailbox.png")
	var postcard = schedule.filter(func(e): return e.kind == "postcard")[0]
	var letter = schedule.filter(func(e): return e.kind == "letter")[0]
	await qa_click(life_panel.actions["mail_" + postcard.id])
	assert(postcard_view.visible and not postcard_view.letter_mode)
	await get_tree().create_timer(0.2).timeout
	assert(postcard_view.wish.get_global_rect().end.y < 710)
	await capture("artifacts/g11-midway-postcard.png")
	await qa_click(postcard_view.close_button)
	await qa_click(life_panel.actions["mail_" + letter.id])
	assert(postcard_view.letter_mode and world.data.trip_count == 0)
	await capture("artifacts/g11-midway-letter.png")
	await qa_click(postcard_view.close_button)
	world.advance(world.data.trip_end + 1)
	var arrived = world.data.postcards[0]
	postcard_view.open(arrived)
	await get_tree().create_timer(0.1).timeout
	assert(postcard_view.wish.get_global_rect().end.y < 710 and not postcard_view.letter_mode)
	await capture("artifacts/g11-arrival-postcard.png")
	postcard_view.hide()
	get_window().size = Vector2i(960, 600)
	await get_tree().create_timer(0.3).timeout
	await capture("artifacts/g11-mailbox-960.png")
	print("G11_NATIVE_PASS: ordered waypoint inbox, unread, postcard, letter, 960px; in-memory progress")
	get_tree().quit()


