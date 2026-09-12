extends SceneTree
const World = preload("res://scripts/reward_world.gd")
var checks = 0
func check(value: bool, description: String) -> void:
	checks += 1
	assert(value, description)
	if not value: quit(1)
func _initialize() -> void:
	var w = World.new()
	check(w.valid_save(w.data), "fresh valid")
	check(not w.command("wear", {"item": "scarf"}).ok, "locked wear rejected")
	check(not w.command("claim_room_reward", {"item": "goldseed"}).ok, "locked gift rejected")
	for id in World.OUTFITS:
		if id != "plain": w.give(World.OUTFITS[id].item)
		var before = w.data.items.duplicate()
		check(w.command("wear", {"item": id}).ok and w.data.outfit == id, "wear " + id)
		check(w.data.items == before, "wear does not consume")
	w.give("silk")
	w.command("sell", {"item": "silk"})
	check(w.outfit_unlocked("scarf"), "duplicate sale preserves outfit")
	for id in World.ROOM_REWARDS:
		w.give(id)
		var coins = w.data.coins
		check(w.command("claim_room_reward", {"item": id}).ok, "claim gift " + id)
		check(not w.command("claim_room_reward", {"item": id}).ok and w.data.coins == coins and w.data.items[id] == 1, "idempotent nonconsuming gift")
	check("flower" in w.data.plant_styles and "lantern" in w.data.decorations and "sunset" in w.data.rugs, "room rewards owned")
	check(w.valid_save(w.data), "equipped save valid")
	var invalid = w.data.duplicate(true)
	invalid.claimed_room_rewards.append("goldseed")
	check(not w.valid_save(invalid), "duplicate claimed gift rejected")
	invalid = w.data.duplicate(true)
	invalid.rugs.erase("sunset")
	check(not w.valid_save(invalid), "claimed gift ownership required")
	var f = FileAccess.open("res://artifacts/g8-save.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(w.data)); f.close()
	var reopened = World.new("res://artifacts/g8-save.json")
	check(reopened.data.outfit == w.data.outfit and reopened.data.claimed_room_rewards.size() == World.ROOM_REWARDS.size(), "reload rewards")
	var old = load("res://scripts/growing_world.gd").new()
	old.give("silk")
	f = FileAccess.open("res://artifacts/g8-v5.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(old.data)); f.close()
	var upgraded = World.new("res://artifacts/g8-v5.json")
	check(upgraded.valid_save(upgraded.data) and upgraded.outfit_unlocked("scarf"), "old collection unlocks retroactively")
	check(FileAccess.file_exists("res://artifacts/g8-v5.json.v5-backup"), "original backup")
	var traveller = World.new()
	traveller.data.foods.feast = 20
	traveller.sync_aliases()
	traveller.rng.seed = 2
	check(traveller.command("travel", {"destination": "hangzhou", "food": "feast"}, 100).ok, "depart")
	# Freeze a successful arrival fixture to test reward settlement independently of random incident rolls.
	traveller.data.trip_snapshot.incident = "ordinary"
	traveller.data.trip_snapshot.common = "silk"
	traveller.data.active_event.destination = "hangzhou"
	traveller.data.active_event.id = "g5_hangzhou_ordinary"
	traveller.advance(traveller.data.trip_end + 1)
	check(traveller.outfit_unlocked("scarf") and "衣橱解锁" in traveller.data.letters[0].rewards, "arrival unlock notification")
	var count = traveller.data.items.silk
	traveller.advance(traveller.clock() + 1)
	check(traveller.data.items.silk == count, "settlement once")
	check(traveller.postcard_content("hangzhou").text == traveller.data.letters[0].text, "postcard uses actual saved diary")
	check(traveller.postcard_content("tokyo").is_empty(), "locked postcard")
	traveller.data.postcards.append("tokyo")
	check(traveller.postcard_content("tokyo").date == "日期未记录", "legacy postcard no invented date")
	print("G8_RULES_PASS: ", checks)
	quit()
