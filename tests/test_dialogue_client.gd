extends SceneTree
const Client = preload("res://scripts/dialogue_client.gd")

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var client = Client.new()
	root.add_child(client)
	client.enabled = true
	client.token_path = "res://artifacts/proxy-test-token"
	client.endpoint = OS.get_cmdline_user_args()[0]
	var facts = {"name": "苔苔", "away": false, "destination": "溪谷", "rain_preference": "unknown", "last_event": "还未旅行"}
	var success = await client.reply("你好", facts)
	assert(success.ok and success.text == "联调测试纸条。")
	assert(not client.busy)
	var failed = await client.reply("请模拟故障", facts)
	assert(not failed.ok and not client.busy)
	print("DIALOGUE_CLIENT_PASS: real HTTP success and fallback (simulated upstream, no paid call)")
	client.queue_free()
	quit()
