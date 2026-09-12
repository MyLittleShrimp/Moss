extends "res://scripts/main.gd"
func texts(node: Node) -> String:
	var all = str(node.text) if node is Label or node is Button else ""
	for child in node.get_children(): all += texts(child)
	return all
func qa_flow() -> void:
	assert(world.save_path.is_empty())
	await get_tree().create_timer(0.4).timeout
	life_panel.open("衣橱")
	var copy = texts(life_panel.body)
	for id in World.OUTFITS:
		if id != "plain": assert(World.OUTFITS[id].name not in copy)
	await capture("artifacts/g9-mystery-wardrobe.png")
	life_panel.open("收藏")
	copy = texts(life_panel.body)
	for id in Content.ITEMS: assert(Content.ITEMS[id].name not in copy)
	await capture("artifacts/g9-mystery-collection.png")
	life_panel.open("田园")
	await qa_click(life_panel.actions.seed_strawberry)
	await qa_click(life_panel.actions.plot0)
	assert(world.data.plot_crops[0] == "strawberry")
	await capture("artifacts/g9-crops.png")
	for id in Content.CROPS: world.data.ingredients[id] = 20
	life_panel.open("厨房")
	for food in ["corn_ball", "veggie_box", "potato_box", "berry_snack"]: await qa_click(life_panel.actions[food])
	assert(world.data.foods.berry_snack == 1)
	await capture("artifacts/g9-foods.png")
	world.data.foods.potato_box = 10
	life_panel.open("远行")
	await qa_click(life_panel.actions.route_iceland)
	await qa_click(life_panel.actions.food_potato_box)
	await qa_click(life_panel.actions.snack)
	world.rng.seed = 2
	world.data.rare_misses.iceland = 7
	await qa_click(life_panel.actions.travel)
	assert(world.data.trip_end > 0 and world.data.foods.berry_snack == 0)
	assert("冰岛" in status.text)
	life_panel.hide()
	world.advance(world.data.trip_end + 1)
	refresh()
	assert(not world.data.pending_discoveries.is_empty())
	await qa_click(parcel_button)
	await capture("artifacts/g9-parcel-before.png")
	await qa_click(parcel_view.open_button)
	await get_tree().create_timer(0.45).timeout
	assert(parcel_view.current != "")
	await capture("artifacts/g9-parcel-reveal.png")
	while not world.data.pending_discoveries.is_empty():
		await qa_click(parcel_view.open_button)
		await get_tree().create_timer(0.45).timeout
	await qa_click(parcel_view.use_button)
	# Fill only the remaining demonstration discoveries in the isolated fixture.
	for id in Content.ITEMS: world.give(id)
	while not world.data.pending_discoveries.is_empty(): world.command("reveal_next")
	for outfit in ["shawl", "beret", "aurora"]:
		life_panel.open("衣橱")
		await qa_click(life_panel.actions["wear_" + outfit])
		assert(world.data.outfit == outfit)
		life_panel.hide()
		await capture("artifacts/g9-outfit-" + outfit + ".png")
	for item in ["tiedye", "coffeecup", "basalt"]:
		world.command("claim_room_reward", {"item": item})
		world.command("decorate", {"item": World.ROOM_REWARDS[item].item})
	refresh()
	await capture("artifacts/g9-room-gifts.png")
	for destination in ["dali", "paris", "iceland"]:
		if destination not in world.data.postcards: world.data.postcards.append(destination)
		world.data.letters.push_front({"destination": destination, "text": world.story(destination, "ordinary"), "trip": 3, "time": world.clock(), "event_id": "g9_" + destination, "title": "一封远方的信", "rewards": "测试纪念"})
		life_panel.open("收藏")
		await qa_click(life_panel.actions["postcard_" + destination])
		await capture("artifacts/g9-postcard-" + destination + ".png")
		await qa_click(postcard_view.close_button)
	DisplayServer.window_set_size(Vector2i(960, 600))
	await get_tree().create_timer(0.4).timeout
	life_panel.open("衣橱")
	await qa_click(life_panel.actions.wear_aurora)
	await capture("artifacts/g9-wardrobe-960.png")
	life_panel.open("远行")
	await qa_click(life_panel.actions.route_dali)
	await capture("artifacts/g9-travel-960.png")
	print("G9_NATIVE_PASS: concealed names/art, crops/foods/snack, journey/parcel/reveal, three outfits/decor/postcards, 960px; in-memory fixtures")
	get_tree().quit()
