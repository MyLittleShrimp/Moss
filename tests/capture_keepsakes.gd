extends "res://scripts/main.gd"
func shot(path):
	await get_tree().create_timer(.25).timeout
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)
func qa_flow():
	for id in world.ROOM_REWARDS:
		world.give(id)
		while not world.data.pending_discoveries.is_empty(): world.command("reveal_next")
		world.command("claim_room_reward", {"item":id})
	world.command("window_cup")
	refresh()
	await shot("res://artifacts/g22-window-cup.png")
	life_panel.open("小屋")
	assert(life_panel.actions.has("window_cup"))
	for id in ["lantern", "tiecloth", "pariscup", "stonelamp"]: assert(life_panel.actions.has(id))
	await shot("res://artifacts/g22-home.png")
	life_panel.open("收藏")
	life_panel.scroll.scroll_vertical = 800
	await shot("res://artifacts/g22-rewards.png")
	print("G22_NATIVE_PASS: all reward placement controls")
	get_tree().quit()
