extends "res://scripts/main.gd"
func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)
func qa_flow() -> void:
	assert(world.save_path.is_empty())
	world.data.foods.mushroom_box = 2
	world.data.foods.feast = 1
	world.data.foods.herb_box = 20
	life_panel.open("远行")
	life_panel.select_destination("hangzhou")
	assert(not life_panel.actions.count_herb_box.editable)
	assert(life_panel.actions.travel.disabled)
	life_panel.actions.count_mushroom_box.value = 1
	life_panel.actions.count_feast.value = 1
	assert(not life_panel.actions.travel.disabled)
	await get_tree().create_timer(0.2).timeout
	life_panel.scroll.scroll_vertical = 2000
	await get_tree().create_timer(0.2).timeout
	assert(life_panel.actions.travel.get_global_rect().end.y < 750)
	await shot("res://artifacts/g16-packing.png")
	await qa_click(life_panel.actions.travel)
	assert(world.data.trip_snapshot.provisions == {"mushroom_box":1,"feast":1})
	world.data.ingredients.herb = 2
	life_panel.open("厨房")
	assert(not life_panel.actions.herb_box.disabled and life_panel.actions.feast.disabled)
	await get_tree().create_timer(0.2).timeout
	life_panel.scroll.scroll_vertical = 2000
	await get_tree().create_timer(0.2).timeout
	await shot("res://artifacts/g16-kitchen.png")
	life_panel.open("小屋")
	assert(life_panel.actions.has("rug_meadow") and life_panel.actions.has("rug_sunset"))
	await qa_click(life_panel.actions.rug_meadow)
	assert(world.data.rug == "meadow")
	await shot("res://artifacts/g16-home.png")
	settings_panel.open()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("http://127.0.0.1:"):
			settings_panel.url.text = argument + "/v1/chat/completions"
			settings_panel.key.text = "fixture-only"
			await settings_panel.refresh_models()
			assert(settings_panel.model_choices.item_count == 2 and not settings_panel.model_choices.disabled)
			settings_panel.model_choices.select(1)
			settings_panel.model_choices.item_selected.emit(1)
			assert(settings_panel.model_name.text == "local-b")
	await shot("res://artifacts/g16-models.png")
	get_window().size = Vector2i(960,600)
	settings_panel.hide()
	life_panel.open("远行")
	await get_tree().create_timer(0.2).timeout
	await shot("res://artifacts/g16-packing-960.png")
	print("G16_NATIVE_PASS: disabled tier; mix counters; sticky departure/kitchen; rugs; model UI; 960px")
	get_tree().quit()
