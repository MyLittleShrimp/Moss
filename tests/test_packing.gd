extends SceneTree
const World = preload("res://scripts/discovery_world.gd")
func _initialize() -> void:
	var world = World.new()
	world.data.foods.mushroom_box = 3
	world.data.foods.feast = 3
	world.data.foods.herb_box = 20
	var before = world.data.foods.duplicate()
	for packed in [{}, {"herb_box":10}, {"mushroom_box":1}, {"mushroom_box":-1}, {"mushroom_box":1.5}, {"mushroom_box":4}, {"bad":1}, {"berry_snack":10}]:
		assert(not world.command("travel", {"destination":"hangzhou", "provisions":packed}).ok)
		assert(world.data.foods == before)
	assert(world.command("travel", {"destination":"hangzhou", "provisions":{"mushroom_box":1,"feast":1}}).ok)
	assert(world.data.foods.mushroom_box == 2 and world.data.foods.feast == 2)
	assert(world.valid_save(world.data))
	var encoded = JSON.parse_string(JSON.stringify(world.data))
	assert(world.valid_save(encoded))
	encoded.trip_snapshot.provisions.mushroom_box = -1
	assert(not world.valid_save(encoded))
	var found = false
	for seed_id in range(100):
		var trial = World.new()
		trial.rng.seed = seed_id
		trial.data.foods.mushroom_box = 1
		trial.data.foods.feast = 1
		assert(trial.command("travel", {"destination":"hangzhou", "provisions":{"mushroom_box":1,"feast":1}}).ok)
		if trial.data.trip_snapshot.incident != "forgot": continue
		trial.advance(trial.data.trip_end + 1)
		assert(trial.data.foods.mushroom_box == 1 and trial.data.foods.feast == 1)
		trial.advance(trial.clock() + 2)
		assert(trial.data.foods.feast == 1)
		found = true
		break
	assert(found)
	var old = World.new()
	old.data.foods.mushroom_box = 3
	assert(old.command("travel", {"destination":"hangzhou", "food":"mushroom_box"}).ok)
	old.data.trip_snapshot.erase("provisions")
	assert(old.valid_save(old.data))
	old.data.rugs = ["woven"]
	old.advance(old.clock())
	assert(old.data.rugs.size() == 3 and old.data.rug == "woven")
	assert(old.valid_save(old.data))
	print("G16_PACKING_PASS: invalid mixes atomic; mixed debit/refund once; JSON/legacy flight; old/new starter rugs")
	quit()
