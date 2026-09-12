extends "res://scripts/main.gd"
## Isolated screenshot fixture; run with --qa. Never opens the player save.
func qa_flow() -> void:
	assert(world.save_path.is_empty())
	get_window().size = Vector2i(1920, 1200)
	await get_tree().create_timer(0.5).timeout
	world.command("remember", {"preference": "like", "source": "我喜欢雨声"})
	world.data.ingredients = {"herb": 6, "rice": 9, "mushroom": 4, "pumpkin": 3}
	world.data.foods = {"herb_box": 2, "rice_ball": 3, "mushroom_box": 4, "feast": 4}
	world.give("stone")
	world.command("place")
	world.sync_aliases()
	conversation = "苔苔：窗台上的青石还在。每次经过它，我都会想起溪边那阵风。"
	notice.text = "种一点喜欢的作物，给下一次远行准备便当。"
	refresh()
	await capture("artifacts/press/g5-01-home.png")
	life_panel.open("田园")
	life_panel.crop = "pumpkin"
	life_panel.rebuild()
	await capture("artifacts/press/g5-02-garden.png")
	life_panel.destination = "istanbul"
	life_panel.food = "feast"
	life_panel.open("远行")
	await capture("artifacts/press/g5-03-journey.png")
	world.data.postcards = Content.ROUTES.keys()
	for id in ["silk", "charm", "ceramic", "blueeye"]: world.give(id)
	world.sync_aliases()
	life_panel.open("收藏")
	await get_tree().process_frame
	life_panel.scroll.scroll_vertical = 10000
	await get_tree().process_frame
	await capture("artifacts/press/g5-04-postcards.png")
	print("PRESS_CAPTURE_PASS: four native screenshots, 1920x1200; isolated fixture; no live AI calls or player save")
	get_tree().quit()
