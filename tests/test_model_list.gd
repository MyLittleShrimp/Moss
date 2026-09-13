extends SceneTree
const Client = preload("res://scripts/player_ai.gd")
func _initialize() -> void: call_deferred("run_test")
func run_test() -> void:
	var client = Client.new()
	root.add_child(client)
	var base = OS.get_cmdline_user_args()[0]
	var good = await client.list_models(base + "/v1/chat/completions", "fixture-only")
	assert(good.ok and good.models == ["local-a", "local-b"])
	assert(client.endpoint.is_empty() and client.api_key.is_empty())
	var bad = await client.list_models(base + "/blocked/chat/completions", "")
	assert(not bad.ok)
	var redirected = await client.list_models(base + "/redirect/chat/completions", "fixture-only")
	assert(not redirected.ok)
	assert(client.parse_models({"models":[{"name":"ollama:8b"}]} ) == ["ollama:8b"])
	assert(client.parse_models({"data":[null,{}, {"id":7}, {"id":"bad\nname"}]}).is_empty())
	assert(not (await client.list_models(base + "/v1/chat/completions", "bad\nheader")).ok)
	print("G16_MODELS_PASS: real HTTP list; sorted/deduped; auth; 404/manual fallback; redirect blocked; input validation; no config changes")
	quit()
