extends "res://scripts/main.gd"
func shot(path: String) -> void:
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)
func qa_flow() -> void:
	assert(world.save_path.is_empty())
	world.data.pace = "balanced"
	world.data.foods.potato_box = 20
	world.data.foods.berry_snack = 1
	world.data.travel_progress.iceland = 2
	world.data.coins = 150
	for crop in world.Content.CROPS: world.data.ingredients[crop] = 10
	life_panel.open("厨房")
	await shot("res://artifacts/g17-kitchen.png")
	life_panel.open("远行")
	life_panel.select_destination("iceland")
	life_panel.actions.count_potato_box.value = 4
	life_panel.bring_snack = true
	life_panel.rebuild()
	await get_tree().create_timer(0.2).timeout
	life_panel.scroll.scroll_vertical = 3000
	await shot("res://artifacts/g17-travel.png")
	assert(not life_panel.actions.travel.disabled)
	world.rng.seed = 2
	await qa_click(life_panel.actions.travel)
	assert(world.data.trip_snapshot.incident != "forgot")
	world.advance(world.data.trip_end + 1)
	assert(world.data.travel_progress.iceland == 3)
	life_panel.open("收藏")
	await get_tree().create_timer(0.2).timeout
	life_panel.scroll.scroll_vertical = 850
	await shot("res://artifacts/g17-album.png")
	postcard_view.open(str(world.data.letters[0].destination))
	assert(postcard_view.message.text.contains("旅册新进展"))
	await shot("res://artifacts/g17-journal.png")
	postcard_view.hide()
	life_panel.open("信箱")
	await shot("res://artifacts/g17-mail.png")
	life_panel.open("小铺")
	await shot("res://artifacts/g17-shop.png")
	get_window().size = Vector2i(960,600)
	life_panel.open("远行")
	await shot("res://artifacts/g17-960.png")
	print("G17_NATIVE_PASS: balanced pace, revised recipes/prices, travel, persistent album, scrollable postcard, mail and 960px")
	get_tree().quit()
