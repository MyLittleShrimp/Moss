extends "res://scripts/main.gd"
func qa_flow() -> void:
	assert(world.save_path.is_empty())
	save_library = load("res://scripts/save_library.gd").new("res://artifacts/g10-native-" + str(Time.get_ticks_usec()))
	ai_client.config_path = save_library.directory + "/ai.cfg"
	ai_client.secret_path = save_library.directory + "/ai.enc"
	await get_tree().create_timer(0.3).timeout
	settings_panel.open()
	await capture("artifacts/g10-settings-ai.png")
	settings_panel.url.text = "http://127.0.0.1:11434/v1/chat/completions"
	settings_panel.model_name.text = "test-local-model"
	await qa_click(settings_panel.actions.save_ai)
	assert(ai_client.model == "test-local-model" and ai_client.api_key.is_empty())
	await qa_click(settings_panel.actions.save_tab)
	await qa_click(settings_panel.actions.new_save)
	var first_id = save_library.active
	world.data.ingredients.herb = 42
	await qa_click(settings_panel.actions.save_as)
	assert(save_library.active != first_id and world.data.ingredients.herb == 42)
	world.data.ingredients.herb = 7
	var index = settings_panel.slot_ids.find(first_id)
	settings_panel.save_list.select(index)
	await qa_click(settings_panel.actions.load_save)
	assert(world.data.ingredients.herb == 42)
	assert(conversation == "苔苔：欢迎回到这间小屋。")
	await capture("artifacts/g10-settings-saves.png")
	var path = save_library.directory + "/portable-export.json"
	settings_panel.file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	settings_panel.file_selected(ProjectSettings.globalize_path(path))
	assert(FileAccess.file_exists(path))
	settings_panel.file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	settings_panel.file_selected(ProjectSettings.globalize_path(path))
	assert(world.data.ingredients.herb == 42)
	ai_client.busy = true
	var previous_world = world
	settings_panel.change_save("new")
	assert(world == previous_world)
	ai_client.busy = false
	get_window().size = Vector2i(960, 600)
	await get_tree().create_timer(0.3).timeout
	settings_panel.ai_page()
	await capture("artifacts/g10-settings-960.png")
	settings_panel.hide()
	world.release_timing = true
	life_panel.open("田园")
	await capture("artifacts/g10-release-crops.png")
	life_panel.open("远行")
	assert(not life_panel.actions.has("pace"))
	await capture("artifacts/g10-release-travel.png")
	print("G10_NATIVE_PASS: settings, save-as, new, load, portable transfer, busy guard, 960px, release UI; fixtures only")
	get_tree().quit()
