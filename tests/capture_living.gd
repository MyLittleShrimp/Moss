extends "res://scripts/main.gd"
## Native pointer QA, in-memory only. Weather/stock fixtures are never player saves.
func qa_flow() -> void:
	assert(world.save_path.is_empty())
	world.data.coins = 70
	for id in Content.CROPS: world.data.ingredients[id] = 8
	world.sync_aliases()
	await get_tree().create_timer(0.4).timeout
	await qa_click(garden_buttons[0])
	await qa_click(life_panel.actions.seed_pumpkin)
	await qa_click(life_panel.actions.plot0)
	assert(world.data.plot_crops[0] == "pumpkin")
	await capture("artifacts/g6-garden.png")
	life_panel.open("厨房")
	await qa_click(life_panel.actions.feast)
	assert(world.data.foods.feast == 1)
	await capture("artifacts/g6-kitchen.png")
	life_panel.open("远行")
	await qa_click(life_panel.actions.route_istanbul)
	life_panel.actions.count_feast.value = 1
	assert(life_panel.destination == "istanbul" and life_panel.provisions.get("feast") == 1)
	life_panel.scroll.scroll_vertical = 0
	await capture("artifacts/g6-routes.png")
	world.give("stone")
	world.give("stone")
	world.sync_aliases()
	life_panel.open("小铺")
	await qa_click(life_panel.actions.sell_stone)
	assert(world.data.coins == 72)
	await qa_click(life_panel.actions.buy_flower)
	assert(world.data.plant_style == "flower" and "plant" in world.data.equipped)
	life_panel.open("小屋")
	await qa_click(life_panel.actions.rug_meadow)
	assert(world.data.rug == "meadow" and world.data.coins == 60)
	await capture("artifacts/g6-shop.png")
	life_panel.hide()
	refresh()
	await qa_click(home_interactions.pot_button)
	assert(home_interactions.moving)
	await capture("artifacts/g6-moving.png")
	await qa_click(home_interactions.destinations[2])
	assert(world.data.plant_spot == "door" and not home_interactions.moving)
	await qa_click(home_interactions.book_button)
	assert(home_interactions.book_panel.visible)
	await qa_click(home_interactions.book_next)
	assert(world.data.book_page == 1)
	await capture("artifacts/g6-book.png")
	await qa_click(home_interactions.book_close)
	world.data.cleanliness = 50
	await qa_click(home_interactions.broom_button)
	assert(world.data.cleanliness == 75 and home_interactions.broom.visible)
	await capture("artifacts/g6-sweeping.png")
	world.data.weather.kind = "rainy"
	world.data.weather.humidity = 86
	refresh()
	await get_tree().create_timer(1.9).timeout
	await capture("artifacts/g6-rainy-home.png")
	world.data.weather.kind = "cloudy"
	world.data.weather.humidity = 68
	refresh()
	await capture("artifacts/g6-cloudy-home.png")
	world.data.weather.kind = "sunny"
	world.data.weather.humidity = 51
	refresh()
	await capture("artifacts/g6-sunny-home.png")
	for id in Content.ROUTES: world.data.postcards.append(id)
	for id in Content.ITEMS: world.give(id)
	world.sync_aliases()
	life_panel.open("收藏")
	await capture("artifacts/g6-collection.png")
	# Minimum supported window still receives pointer input and keeps modal inside viewport.
	get_window().size = Vector2i(960, 600)
	await get_tree().create_timer(0.35).timeout
	life_panel.open("厨房")
	await qa_click(life_panel.actions.herb_box)
	await capture("artifacts/g6-small-window.png")
	print("SMALL_QA: food=", world.data.foods.herb_box, " viewport=", get_viewport_rect(), " button=", life_panel.actions.herb_box.get_global_rect(), " notice=", notice.text)
	assert(world.data.foods.herb_box == 1)
	print("G6_UI_PASS: illustrated seed/recipe/route/food cards, exchange, flower/rug purchase, direct pot click and move, book paging, sweep animation, three weather views, 960x600 interaction; in-memory only")
	get_tree().quit()
