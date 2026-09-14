extends "res://scripts/main.gd"
func shot(path):
	await get_tree().create_timer(.3).timeout
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(path) == OK)
func qa_flow():
	assert(world.save_path.is_empty())
	settings_panel.open()
	settings_panel.url.text = "https://example.com/v1"
	await shot("res://artifacts/g21-settings.png")
	settings_panel.image_page()
	await shot("res://artifacts/g21-image-settings.png")
	settings_panel.hide()
	print("G21_NATIVE_PASS")
	get_tree().quit()
