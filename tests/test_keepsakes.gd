extends SceneTree
const World = preload("res://scripts/discovery_world.gd")
func _initialize():
	var w = World.new()
	assert(not w.command("window_cup").ok)
	w.give("teacup")
	w.command("reveal_next")
	assert(w.command("claim_room_reward", {"item":"teacup"}).ok)
	w.give("stone")
	w.sync_aliases()
	w.command("reveal_next")
	assert(w.command("place").ok)
	var coins = w.data.coins
	assert(w.command("window_cup").ok and w.data.window_cup and not w.data.placed)
	assert(w.valid_save(w.data))
	assert(w.command("place").ok and w.data.placed and not w.data.window_cup)
	w.command("window_cup")
	w.command("window_cup")
	assert(not w.data.window_cup and not w.data.placed and w.data.coins == coins)
	var legacy = w.data.duplicate(true)
	legacy.erase("window_cup")
	legacy.plant_styles = ["leaf"]
	if "plant" not in legacy.decorations: legacy.decorations.append("plant")
	assert(w.valid_save(legacy))
	var path = "res://artifacts/g22-keepsake-save.json"
	w.save_path = path; w.data = legacy
	w.command("window_cup")
	var loaded = World.new(path)
	assert(loaded.data.window_cup and "teacup" in loaded.data.claimed_room_rewards)
	assert("plant" in loaded.data.decorations)
	print("G22_KEEPSAKES_PASS: claim, legacy ownership, replace, hide, reload, no cost")
	quit()
