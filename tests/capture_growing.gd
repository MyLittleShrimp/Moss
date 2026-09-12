extends "res://scripts/main.gd"
func ai_facts() -> Dictionary:
	if "--livebook" in OS.get_cmdline_user_args():
		# Literal synthetic QA data only. Never send player save, name or preferences.
		return {"name": "虚构测试蛙", "away": false, "destination": "虚构小溪", "rain_preference": "unknown", "last_event": "测试故事尚未开始", "preferences": ["喜欢虚构的蓝色花朵"], "observations": [], "weather": "sunny", "book_day": "2026-09-11"}
	return super.ai_facts()

func qa_flow() -> void:
	assert(world.save_path.is_empty())
	world.data.coins = 70
	world.command("home_buy", {"kind": "plant", "item": "flower"})
	await get_tree().create_timer(0.4).timeout
	for style in ["leaf", "flower"]:
		world.command("plant_style", {"item": style})
		for spot in ["window", "desk", "door"]:
			world.command("plant_move", {"item": spot})
			refresh()
			assert(room_key == style + "-" + spot)
			assert(not home_interactions.pot.visible)
			await capture("artifacts/g7-" + room_key + ".png")
	await qa_click(home_interactions.pot_hide)
	assert("plant" not in world.data.equipped and room_key == "empty")
	await capture("artifacts/g7-empty.png")
	life_panel.open("小屋")
	await qa_click(life_panel.actions.plant_leaf)
	assert("plant" in world.data.equipped)
	life_panel.hide()
	await qa_click(home_interactions.pot_hint)
	await qa_click(home_interactions.destinations[0])
	assert(world.data.plant_spot == "window")
	await qa_click(home_interactions.book_button)
	assert(world.data.daily_book.source == "local")
	if "--livebook" in OS.get_cmdline_user_args():
		ai_client.enabled = true
		ai_toggle.button_pressed = true
		await home_interactions.open_book(0)
		assert(world.data.daily_book.source == "llm", "live daily book must validate")
		await capture("artifacts/g7-book-live.png")
		ai_client.enabled = false
		ai_toggle.button_pressed = false
		print("G7_LIVE_BOOK_PASS: authenticated proxy -> DeepSeek -> dated cache, one attempt")
	await qa_click(home_interactions.book_next)
	assert(world.data.book_page == 1)
	await capture("artifacts/g7-book.png")
	await qa_click(home_interactions.book_close)
	world.data.cleanliness = 50
	await qa_click(home_interactions.broom_button)
	assert(world.data.cleanliness == 75)
	await capture("artifacts/g7-sweep.png")
	await send_text("我喜欢茉莉花")
	await send_text("我喜欢羽生结弦")
	await send_text("我不喜欢很吵的地方")
	set_tab("记忆")
	var topic = life_panel.body.find_child("PreferenceTopic", true, false)
	topic.text = "安静的海边"
	await qa_click(life_panel.actions.memory_save)
	assert(world.data.preferences.has("安静的海边"))
	await qa_click(life_panel.actions["forget_茉莉花"])
	assert(not world.data.preferences.has("茉莉花"))
	life_panel.scroll.scroll_vertical = 0
	await capture("artifacts/g7-memory.png")
	DisplayServer.window_set_size(Vector2i(960, 600))
	await get_tree().create_timer(0.3).timeout
	await capture("artifacts/g7-memory-960.png")
	life_panel.hide()
	await qa_click(home_interactions.book_button)
	await qa_click(home_interactions.book_next)
	assert(world.data.book_page == 2)
	await capture("artifacts/g7-book-960.png")
	print("G7_NATIVE_PASS: six scenes, hide/show, pointer move, daily book, sweep, memory CRUD, 960px; in-memory save")
	get_tree().quit()
