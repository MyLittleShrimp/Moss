extends SceneTree
const Client = preload("res://scripts/player_ai.gd")
const World = preload("res://scripts/discovery_world.gd")
const Book = preload("res://scripts/yearbook.gd")
var checks = 0
var failed = false
var world = World.new()
var ai_client
func check(value, label):
	checks += 1
	if not value: failed = true; push_error(label)
func _initialize(): call_deferred("run_test")
func run_test():
	ai_client = Client.new(); root.add_child(ai_client)
	for url in ["https://example.com/v1", "https://example.com/custom/generate?api-version=2026", "http://localhost:11434/api/chat"]:
		check(ai_client.validation(url, "fixture").is_empty(), "accept " + url)
	check(ai_client.normalized_endpoint("https://example.com/v1/") == "https://example.com/v1/chat/completions", "base normalization")
	check(ai_client.normalized_endpoint("https://example.com/custom?x=1") == "https://example.com/custom?x=1", "custom unchanged")
	check(ai_client.normalized_endpoint("https://example.com/custom/") == "https://example.com/custom/", "custom trailing slash unchanged")
	check(not ai_client.validation("https://example.com/chat?api_key=fixture", "fixture").is_empty(), "URL secret rejected")
	Book.entry("2026-01-01")
	check(Book.entries.size() == 366, "leap year count")
	var unique = {}
	for id in Book.entries:
		var entry = Book.entry("2024-" + id)
		check(entry.pages.size() == 3, "three pages")
		unique[JSON.stringify(entry.pages)] = true
	check(unique.size() == 366, "unique daily texts")
	world.ensure_book("2026-01-01")
	var first = world.data.daily_book.duplicate(true)
	world.ensure_book("2026-01-01")
	check(first == world.data.daily_book, "stable today")
	world.ensure_book("2026-01-02")
	check(first.pages != world.data.daily_book.pages, "different tomorrow")
	check(world.valid_save(world.data), "yearbook save valid")
	var image_config = preload("res://scripts/postcard_image_config.gd").new()
	image_config.config_path = "res://artifacts/g21-image.cfg"
	image_config.secret_path = "res://artifacts/g21-image.enc"
	check(image_config.configure("https://example.com/v1", "fixture", "fixture-only", "1024x1024", true, "fixture-password").is_empty(), "image config encrypted")
	check(not FileAccess.get_file_as_string(image_config.config_path).contains("fixture-only"), "no plaintext image key")
	image_config.api_key = ""
	image_config.load_settings()
	check(image_config.api_key.is_empty() and image_config.unlock("fixture-password"), "explicit image key unlock")
	check(not image_config.capability().implemented and not JSON.stringify(image_config.build_payload("溪谷")).contains("fixture-only"), "image seam no secret payload")
	var base = OS.get_cmdline_user_args()[0]
	ai_client.model = "fixture"; ai_client.enabled = true
	for path in ["/v1/chat/completions", "/custom", "/api/chat"]:
		ai_client.endpoint = base + path
		var result = await ai_client.reply("fixture", {}, "travel_mail")
		check(result.ok, "network protocol " + path)
	ai_client.endpoint = base + "/custom"
	world.data.letters.append({"trip":1, "time":123, "destination":"creek", "event_id":"fixture", "text":"溪边的风很轻。"})
	var service = preload("res://scripts/narrative_service.gd").new(self)
	root.add_child(service)
	var before = world.data.coins
	service.request_entry("travel", world.data.letters[-1])
	await process_frame
	while service.running: await process_frame
	check(world.data.letters[-1].get("ai_text", "") == "窗外的风很轻，我把一片云写进信里。", "AI prose cached")
	check(world.data.letters[-1].text == "溪边的风很轻。" and world.data.coins == before, "local text and economy untouched")
	world.data.letters[-1].erase("ai_text")
	ai_client.endpoint = base + "/slow"
	service.request_entry("travel", world.data.letters[-1], true)
	await create_timer(0.1).timeout
	ai_client.generation += 1
	while service.running: await process_frame
	check(not world.data.letters[-1].has("ai_text"), "stale configuration rejected")
	ai_client.endpoint = base + "/failure"
	service.request_entry("travel", world.data.letters[-1], true)
	await process_frame
	while service.running: await process_frame
	check(not world.data.letters[-1].has("ai_text") and world.data.letters[-1].text == "溪边的风很轻。", "HTTP failure preserves local fallback")
	print("G21_PASS: ", checks, " checks")
	quit(1 if failed else 0)
