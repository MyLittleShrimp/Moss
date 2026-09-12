extends SceneTree
const Client = preload("res://scripts/player_ai.gd")
func _initialize() -> void:
	call_deferred("run_test")
func run_test() -> void:
	var client = Client.new()
	root.add_child(client)
	client.endpoint = OS.get_cmdline_user_args()[0]
	client.model = "fixture"
	client.enabled = true
	var facts = {"name": "虚构角色"}
	var good = await client.reply("hello", facts)
	assert(good.ok and good.text == "模型接口测试。")
	var rejected = await client.reply("unauthorized", facts)
	assert(not rejected.ok and "401" in client.status_text)
	var malformed = await client.reply("malformed", facts)
	assert(not malformed.ok)
	var redirect = await client.reply("redirect", facts)
	assert(not redirect.ok)
	client.timeout_seconds = 0.2
	var timeout = await client.reply("timeout", facts)
	assert(not timeout.ok and not client.busy)
	client.timeout_seconds = 3
	var again = await client.test_connection()
	assert(again.ok)
	print("G10_HTTP_PASS: real loopback HTTP, keyless Ollama-compatible request, 401, invalid output, redirect, timeout, recovery; simulated model")
	client.queue_free()
	quit()
