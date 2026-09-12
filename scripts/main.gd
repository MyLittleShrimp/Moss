extends Control

const World = preload("res://scripts/discovery_world.gd")
var parcel_view
var parcel_button: Button
var mail_button: Button
var postcard_view
var worn_outfit = ""
const Content = preload("res://scripts/game_content.gd")
var life_panel
var decor
var home_interactions
var room_background: TextureRect
var room_key = ""
var room_textures = {}
var room_floor
const Dialogue = preload("res://scripts/local_dialogue.gd")
const AIClient = preload("res://scripts/player_ai.gd")
var save_library
var settings_panel
const Catalog = preload("res://scripts/travel_catalog.gd")
const INK = Color("35483d")
const MUTED = Color("768072")
const PAPER = Color("fbf8ee")
const GREEN = Color("526e51")
var world: PetWorld
var dialogue = Dialogue.new()
var frog: TextureRect
var frog_base = Vector2(408, 496)
var notice: Label
var status: Label
var inventory: Label
var journal: RichTextLabel
var input: LineEdit
var garden_buttons: Array[Button] = []
var cook_button: Button
var travel_button: Button
var place_button: Button
var stone: Label
var pet_label: Label
var tab = "手记"
var elapsed = 0.0
var tick = 0.0
var conversation = "苔苔：欢迎回家。种一点香草吧，今天想去溪谷散步。"
var qa_mode = false
var ai_client
var ai_toggle: CheckButton
var ai_label: Label
var route: OptionButton
var letter_index = 0
var letter_previous: Button
var letter_next: Button
var reply_source = "本地规则对话"

func _ready() -> void:
	qa_mode = "--qa" in OS.get_cmdline_user_args() or "--qa-live" in OS.get_cmdline_user_args() or "--smoke-test" in OS.get_cmdline_user_args()
	save_library = load("res://scripts/save_library.gd").new("memory://" if qa_mode else "")
	world = World.new() if qa_mode else save_library.initial()
	if world == null:
		world = World.new()
		world.warning = save_library.error
	world.release_timing = load("res://scripts/build_profile.gd").release_build()
	ai_client = AIClient.new()
	add_child(ai_client)
	if not qa_mode: ai_client.load_settings()
	var font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	var game_theme = Theme.new()
	game_theme.default_font = font
	game_theme.default_font_size = 17
	theme = game_theme
	build_ui()
	decor = load("res://scripts/house_decor.gd").new()
	add_child(decor)
	home_interactions = load("res://scripts/home_interactions.gd").new(self)
	add_child(home_interactions)
	home_interactions.weather_canvas.reparent(self)
	move_child(home_interactions.weather_canvas, frog.get_index() + 1)
	life_panel = load("res://scripts/life_panel.gd").new(self)
	add_child(life_panel)
	postcard_view = load("res://scripts/postcard_view.gd").new(self)
	add_child(postcard_view)
	parcel_button = button_at("拆开旅行包裹", Rect2(480, 17, 240, 37), func(): parcel_view.open())
	mail_button = button_at("途中信箱", Rect2(730, 17, 140, 37), func(): life_panel.open("信箱"))
	parcel_view = load("res://scripts/parcel_view.gd").new(self)
	add_child(parcel_view)
	settings_panel = load("res://scripts/settings_panel.gd").new(self)
	add_child(settings_panel)
	button_at("设置 · 存档", Rect2(880, 17, 170, 37), func(): settings_panel.open())
	refresh()
	if "--smoke-test" in OS.get_cmdline_user_args():
		assert(world.save_path.is_empty())
		if "--expect-release" in OS.get_cmdline_user_args(): assert(world.release_timing)
		if "--expect-development" in OS.get_cmdline_user_args(): assert(not world.release_timing)
		print("G10_PACKAGE_SMOKE_PASS: ", "release" if world.release_timing else "development", "; no player save, no model request")
	if not world.warning.is_empty():
		notice.text = world.warning
	if "--qa-live" in OS.get_cmdline_user_args():
		call_deferred("live_qa_flow")
	elif qa_mode and "--smoke-test" not in OS.get_cmdline_user_args():
		call_deferred("qa_flow")

func live_qa_flow() -> void:
	await get_tree().create_timer(0.5).timeout
	ai_toggle.button_pressed = true
	var before = world.data.duplicate(true)
	await send_text("今天有点累，可以陪我坐一会儿吗？")
	assert(reply_source.begins_with("LLM 生成"), "live DeepSeek reply must pass validation")
	assert(world.data.herbs == before.herbs and world.data.meals == before.meals and world.data.souvenirs == before.souvenirs)
	await capture("artifacts/g4-live-dialogue.png")
	print("G4_LIVE_UI_PASS: Godot -> local proxy -> DeepSeek -> validated text; inventory unchanged; in-memory test save")
	get_tree().quit()

func panel(rect: Rect2, color: Color, radius: int = 18) -> Panel:
	var node = Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.add_theme_stylebox_override("panel", box(color, radius))
	add_child(node)
	return node

func box(color: Color, radius: int = 12) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func label_at(text: String, rect: Rect2, font_size: int = 18, color: Color = INK) -> Label:
	var node = Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func button_at(text: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_stylebox_override("normal", box(GREEN if primary else Color("f5efdf")))
	node.add_theme_stylebox_override("hover", box(Color("6e895d") if primary else Color("e7dec7")))
	node.add_theme_stylebox_override("pressed", box(Color("82966b")))
	node.add_theme_stylebox_override("disabled", box(Color("e8e6dd")))
	node.add_theme_color_override("font_color", PAPER if primary else INK)
	node.add_theme_color_override("font_hover_color", PAPER if primary else INK)
	node.add_theme_color_override("font_disabled_color", MUTED)
	node.pressed.connect(callback)
	add_child(node)
	return node

func build_ui() -> void:
	panel(Rect2(0, 0, 1440, 900), Color("f1efe5"), 0)
	label_at("M O S S  &  M O M E N T S", Rect2(28, 20, 570, 24), 13, MUTED)
	label_at("苔间小屋", Rect2(24, 46, 450, 58), 38)
	label_at("把日子过慢一点，把回忆留下来。", Rect2(236, 65, 500, 32), 17, MUTED)
	status = label_at("", Rect2(1010, 32, 405, 33), 19)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ai_label = label_at("本地规则对话", Rect2(1050, 76, 365, 24), 13, MUTED)
	ai_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ai_toggle = CheckButton.new()
	ai_toggle.text = "启用 AI 对话"
	ai_toggle.position = Vector2(785, 69)
	ai_toggle.size = Vector2(235, 35)
	ai_toggle.add_theme_color_override("font_color", INK)
	ai_toggle.add_theme_color_override("font_pressed_color", INK)
	ai_toggle.add_theme_color_override("font_hover_color", INK)
	ai_toggle.add_theme_color_override("font_hover_pressed_color", INK)
	ai_toggle.tooltip_text = "先在设置中配置自己的模型；启用后会发送本次纸条与相关游戏上下文。"
	ai_toggle.toggled.connect(func(on): ai_client.enabled = on)
	add_child(ai_toggle)
	var image = TextureRect.new()
	room_background = image
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = load("res://assets/cottage-g6.png")
	image.position = Vector2(24, 128)
	image.size = Vector2(1010, 674)
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)
	room_floor = load("res://scripts/room_floor.gd").new()
	add_child(room_floor)
	panel(Rect2(44, 148, 198, 40), Color(0.98, 0.97, 0.92, 0.92), 20)
	label_at("小屋与庭院  ·  午后", Rect2(59, 150, 180, 36), 15)
	frog = TextureRect.new()
	frog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frog.texture = load("res://assets/frog.png")
	frog.position = frog_base
	frog.size = Vector2(150, 156)
	frog.pivot_offset = Vector2(75, 150)
	frog.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frog)
	pet_label = label_at("苔苔 · 在家发呆", Rect2(377, 661, 224, 31), 16, Color("faf6e6"))
	pet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_label.add_theme_color_override("font_shadow_color", Color("4a553d"))
	pet_label.add_theme_constant_override("shadow_offset_y", 2)
	for index in range(3):
		var button = button_at("选择作物", Rect2(826 - index * 18, 407 + index * 80, 168, 43), func():
			if float(world.data.plots[index]) > 0: act("garden", {"plot": index})
			else: life_panel.open("田园"))
		button.tooltip_text = "打开田园选择作物；已成熟可直接收获。"
		garden_buttons.append(button)
	stone = label_at("●", Rect2(277, 270, 44, 40), 32, Color("779b95"))
	stone.add_theme_color_override("font_shadow_color", Color("3f655d"))
	stone.add_theme_constant_override("shadow_offset_y", 3)
	panel(Rect2(44, 722, 966, 60), Color(0.98, 0.97, 0.92, 0.95), 14)
	notice = label_at("先点右边的花圃，种下今天的第一株香草。", Rect2(62, 731, 925, 40), 17)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel(Rect2(1058, 128, 358, 674), PAPER)
	label_at("今日的小日子", Rect2(1082, 148, 310, 40), 25)
	inventory = label_at("", Rect2(1082, 194, 310, 30), 15, MUTED)
	for index in range(3):
		var title = ["手记", "记忆", "旅途"][index]
		button_at(title, Rect2(1080 + index * 105, 242, 97, 40), func(): set_tab(title))
	letter_previous = button_at("← 较新", Rect2(1081, 287, 147, 36), func(): browse_letter(-1))
	letter_next = button_at("较早 →", Rect2(1236, 287, 157, 36), func(): browse_letter(1))
	journal = RichTextLabel.new()
	journal.position = Vector2(1083, 302)
	journal.size = Vector2(305, 291)
	journal.add_theme_color_override("default_color", INK)
	journal.add_theme_font_size_override("normal_font_size", 17)
	journal.add_theme_constant_override("line_separation", 4)
	journal.bbcode_enabled = false
	add_child(journal)
	button_at("写下我的喜好", Rect2(1081, 603, 147, 38), func(): life_panel.open("记忆"))
	button_at("整理记忆本", Rect2(1236, 603, 157, 38), func(): life_panel.open("记忆"))
	input = LineEdit.new()
	input.position = Vector2(1081, 659)
	input.size = Vector2(310, 43)
	input.placeholder_text = "和苔苔说句话…"
	input.max_length = 200
	input.add_theme_stylebox_override("normal", box(Color("edeadd")))
	input.add_theme_color_override("font_color", INK)
	input.add_theme_color_override("font_placeholder_color", MUTED)
	input.text_submitted.connect(send_text)
	add_child(input)
	button_at("留一张小纸条  ↗", Rect2(1081, 718, 310, 48), func(): send_text(input.text), true)
	panel(Rect2(24, 819, 1392, 62), PAPER, 16)
	button_at("田园 · 选择作物", Rect2(44, 828, 310, 44), func(): life_panel.open("田园"))
	route = OptionButton.new()
	route.position = Vector2(145, 830)
	route.size = Vector2(310, 40)
	for destination in Catalog.DESTINATIONS.values():
		route.add_item(destination)
	route.add_theme_stylebox_override("normal", box(Color("f5efdf")))
	route.add_theme_color_override("font_color", INK)
	route.item_selected.connect(func(_index): refresh())
	add_child(route)
	route.hide()
	cook_button = button_at("厨房 · 制作食物", Rect2(374, 828, 310, 44), func(): life_panel.open("厨房"))
	travel_button = button_at("远行 · 打点行囊", Rect2(704, 828, 310, 44), func(): life_panel.open("远行"), true)
	place_button = button_at("收藏 · 小铺 · 小屋", Rect2(1034, 828, 360, 44), func(): life_panel.open("收藏"))

func set_tab(value: String) -> void:
	tab = value
	refresh()
	if value == "记忆": life_panel.open("记忆")

func browse_letter(direction: int) -> void:
	letter_index = clampi(letter_index + direction, 0, maxi(0, world.data.letters.size() - 1))
	refresh()

func destination_name() -> String:
	return Content.ROUTES[world.data.trip_snapshot.get("planned", world.data.active_event.get("destination", "creek"))].name

func act(action: String, payload: Dictionary = {}) -> void:
	if action == "travel" and payload.is_empty():
		payload = {"destination": Catalog.DESTINATIONS.keys()[route.selected]}
	var result = world.command(action, payload)
	if action == "sweep" and result.ok: home_interactions.animate_sweep()
	notice.text = result.message
	if not world.warning.is_empty():
		notice.text = world.warning
	if action == "travel" and result.ok:
		tab = "旅途"
	if action == "place" and result.ok:
		conversation = "苔苔：青石放在那里刚刚好。以后经过窗边，就能想起我们今天的小旅行。"
		tab = "手记"
	refresh()

func send_text(text: String) -> void:
	if text.strip_edges().is_empty():
		return
	var before = int(world.data.revision)
	var fallback = dialogue.respond(text.left(200), world)
	var memory_changed = int(world.data.revision) != before
	if ai_client.busy and not memory_changed:
		notice.text = "上一张纸条还在写，稍等一下就好。"
		return
	conversation = "你：" + text.left(200) + "\n\n苔苔：" + fallback
	reply_source = "记忆更新 · 本地规则" if memory_changed else "本地规则对话"
	if not ai_client.busy:
		ai_client.status_text = reply_source
	input.clear()
	tab = "手记"
	refresh()
	if not memory_changed and ai_client.enabled:
		var requesting_world = world
		var version = int(world.data.revision)
		var facts = ai_facts()
		var result = await ai_client.reply(text.left(200), facts)
		if world != requesting_world or version != int(world.data.revision) or not ai_client.enabled:
			ai_client.status_text = "状态已变化 · 未采用旧回复"
			refresh()
			return
		if result.ok:
			conversation = "你：" + text.left(200) + "\n\n苔苔：" + result.text
			reply_source = "LLM 生成 · 仅文本，不改变道具"
		else:
			reply_source = ai_client.status_text
		refresh()

func ai_facts() -> Dictionary:
	return {"name": str(world.data.name), "away": float(world.data.trip_end) > 0,
		"destination": destination_name(), "rain_preference": str(world.data.rain_preference),
		"last_event": str(world.data.letters[0].get("title", "溪谷散步")) if not world.data.letters.is_empty() else "还未旅行",
		"preferences": world.preference_lines(), "observations": world.observations().slice(0, 12),
		"weather": str(world.data.weather.kind), "book_day": world.today()}

func refresh_room() -> void:
	var key = world.data.plant_style + "-" + world.data.plant_spot if "plant" in world.data.equipped else "empty"
	if key == room_key: return
	var path = "res://assets/cottage-g6.png" if key == "empty" else "res://assets/rooms/" + key + ".png"
	if not ResourceLoader.exists(path): return
	if not room_textures.has(key): room_textures[key] = load(path)
	room_background.texture = room_textures[key]
	room_key = key

func refresh() -> void:
	if parcel_button != null:
		parcel_button.visible = not world.data.pending_discoveries.is_empty()
		parcel_button.text = "拆开旅行包裹 · %d 个新发现" % world.data.pending_discoveries.size()
	if worn_outfit != world.data.outfit:
		frog.texture = load("res://assets/frog.png" if world.data.outfit == "plain" else "res://assets/outfits/" + world.data.outfit + ".png")
		worn_outfit = world.data.outfit
	refresh_room()
	var now = world.clock()
	var away = float(world.data.trip_end) > 0
	status.text = "去往%s · 归期未定" % destination_name() if away else "● 苔苔在家 · " + {"well": "精神很好", "ill": "有点着凉", "mood": "想静一静"}[world.data.condition]
	ai_label.text = ai_client.status_text if ai_client.enabled else "AI 未启用 · 本地规则对话"
	route.disabled = away
	travel_button.text = "旅途中 · 归期未定" if away else "远行 · 打点行囊"
	letter_previous.visible = tab == "旅途" and not world.data.letters.is_empty()
	letter_next.visible = letter_previous.visible
	letter_previous.disabled = letter_index == 0
	letter_next.disabled = letter_index >= world.data.letters.size() - 1
	journal.position.y = 337 if letter_previous.visible else 302
	journal.size.y = 256 if letter_previous.visible else 291
	inventory.text = "食物 %d  /  收藏 %d种  /  叶币 %d" % [world.data.meals, world.data.collected.size(), world.data.coins]
	for index in range(3):
		var end = float(world.data.plots[index])
		var crop_name = Content.CROPS[world.data.plot_crops[index]].name
		garden_buttons[index].text = "＋ 选择作物" if end == 0 else ("✦ 收获" + crop_name if now >= end else crop_name + " · %ds" % ceili(end - now))
		garden_buttons[index].disabled = end > now
	cook_button.disabled = false
	travel_button.disabled = false
	place_button.disabled = false
	decor.state = world.data
	decor.queue_redraw()
	room_floor.state = world.data
	home_interactions.refresh()
	stone.visible = bool(world.data.placed)
	frog.visible = not away
	pet_label.visible = not away
	pet_label.text = "苔苔 · 惦记窗边的青石" if world.data.placed else "苔苔 · 在家发呆"
	if world.data.condition != "well": pet_label.text = "苔苔 · " + ("想喝一碗热汤" if world.data.condition == "ill" else "想安静待一会儿")
	match tab:
		"手记":
			journal.text = conversation + "\n\n——\n" + reply_source
		"记忆":
			journal.text = "它记住的小事\n\n" + "\n".join(world.preference_lines()) + "\n\n生活足迹\n" + "\n".join(world.observations())
		"旅途":
			journal.text = "等一封远方的信\n\n" + ("苔苔带着便当，在路上慢慢走。关掉游戏后，旅程也会继续。" if away else "去厨房做好食物，在远行中挑一个目的地。更远的地方，需要更充足的行囊。")
			if not world.data.letters.is_empty():
				var letter = world.data.letters[clampi(letter_index, 0, world.data.letters.size() - 1)]
				journal.text = "%s · 第 %d 次\n%s\n\n%s\n\n随信带回：%s" % [Content.ROUTES.get(letter.get("destination", "creek"), Content.ROUTES.creek).name, letter.trip, letter.get("title", "旧日的小旅行"), letter.text, letter.get("rewards", "一份纪念")]

func _process(delta: float) -> void:
	if world == null:
		return
	elapsed += delta
	tick += delta
	var base = Vector2(245, 356) if bool(world.data.placed) and sin(elapsed / 8.0) > 0.4 else frog_base
	frog.position = frog.position.lerp(base + Vector2(sin(elapsed * 0.5) * 13, sin(elapsed * 2.0) * 2.5), delta * 1.4)
	frog.rotation = sin(elapsed * 1.4) * 0.017
	if tick > 0.25:
		tick = 0
		var previous_revision = world.data.revision
		if world.advance(world.clock()):
			letter_index = 0
			notice.text = "门外传来脚步声——苔苔回家了，还带着一封信。"
			tab = "旅途"
		elif world.mail_arrivals > 0:
			notice.text = "信箱里多了 %d 封途中来信，苔苔把沿途的小日子寄回来了。" % world.mail_arrivals
		world.mail_arrivals = 0
		if world.data.revision != previous_revision and life_panel.visible: life_panel.rebuild()
		refresh()
		var unread = 0
		for entry in world.data.get("travel_mail", []):
			if not entry.read: unread += 1
		mail_button.text = "途中信箱 · %d" % unread if unread > 0 else "途中信箱"

func qa_flow() -> void:
	await get_tree().create_timer(0.5).timeout
	assert(world.save_path.is_empty())
	world.rng.seed = 2
	await capture("artifacts/g5-home.png")
	await qa_click(garden_buttons[0])
	assert(life_panel.visible and life_panel.page == "田园")
	await qa_click(life_panel.actions.plot0)
	assert(world.data.plots[0] > 0)
	await capture("artifacts/g5-garden.png")
	world.data.plots[0] = world.clock() - 1
	life_panel.rebuild()
	await get_tree().process_frame
	await qa_click(life_panel.actions.plot0)
	assert(world.data.ingredients.herb == 2)
	life_panel.hide()
	await qa_click(cook_button)
	await get_tree().process_frame
	await qa_click(life_panel.actions.herb_box)
	assert(world.data.foods.herb_box == 1)
	await capture("artifacts/g5-kitchen.png")
	life_panel.hide()
	await qa_click(travel_button)
	await get_tree().process_frame
	await qa_click(life_panel.actions.travel)
	assert(world.data.trip_end > 0 and "归期未定" in status.text)
	await capture("artifacts/g5-travel.png")
	life_panel.hide()
	world.advance(world.data.trip_end + 1)
	refresh()
	assert(world.data.letters.size() == 1)
	# Fixture stocks only in memory allow UI coverage beyond a single short trip.
	for id in Content.ROUTES:
		if id not in world.data.postcards: world.data.postcards.append(id)
	for id in Content.ITEMS: world.give(id)
	while not world.data.pending_discoveries.is_empty(): world.command("reveal_next")
	world.give("stone")
	world.data.coins = 60
	world.sync_aliases()
	life_panel.open("收藏")
	await capture("artifacts/g5-collection.png")
	life_panel.scroll.scroll_vertical = 620
	await capture("artifacts/g5-postcards.png")
	life_panel.open("小铺")
	await get_tree().process_frame
	await qa_click(life_panel.actions.sell_stone)
	assert(world.data.coins == 62)
	# Scroll to an actual furniture button before delivering pointer input.
	life_panel.scroll.ensure_control_visible(life_panel.actions.buy_plant)
	await get_tree().process_frame
	await qa_click(life_panel.actions.buy_plant)
	assert("plant" in world.data.equipped)
	await capture("artifacts/g5-shop.png")
	world.command("buy", {"kind": "decor", "item": "lantern"})
	world.command("buy", {"kind": "decor", "item": "bunting"})
	world.command("place")
	life_panel.hide()
	refresh()
	await capture("artifacts/g5-decorated.png")
	world.data.condition = "mood"
	world.data.recovery_end = world.clock() + 600
	life_panel.open("照料")
	await capture("artifacts/g5-care.png")
	await qa_click(life_panel.actions.care)
	assert(world.data.condition == "well")
	life_panel.hide()
	ai_client.queue_free()
	ai_client = load("res://tests/delayed_client.gd").new()
	add_child(ai_client)
	send_text("聊聊今天")
	world.command("remember", {"preference": "dislike", "source": "测试期间纠正"})
	await get_tree().create_timer(0.2).timeout
	assert("SHOULD_NOT_APPEAR" not in conversation and "未采用旧回复" in ai_client.status_text)
	print("G5_UI_PASS: pointer planting -> harvest -> cook -> departure -> postcard -> duplicate exchange -> furniture -> care; stale AI reply rejected; no user save")
	get_tree().quit()

func qa_click(button: Control) -> void:
	# Rebuilt grids need layout before scroll-to-child can compute a valid offset.
	await get_tree().process_frame
	await get_tree().process_frame
	var parent = button.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
		parent = parent.get_parent()
	await get_tree().process_frame
	await get_tree().process_frame
	var point = button.get_global_rect().get_center()
	var event = InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	get_viewport().push_input(event, true)
	await get_tree().process_frame
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event, true)
	await get_tree().process_frame

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() != "headless":
		var image = get_viewport().get_texture().get_image()
		var target = path if "g4-" in path or "g5-" in path or "g6-" in path or "g7-" in path or "g8-" in path or "g9-" in path or "g10-" in path or "g11-" in path else path.replace("artifacts/", "artifacts/g3-")
		if path.begins_with("artifacts/g5-"): target = path.replace("artifacts/g5-", "artifacts/g11-regression-")
		var result = image.save_png(ProjectSettings.globalize_path("res://" + target))
		assert(result == OK)

func activate_save(next) -> void:
	world = next
	world.release_timing = load("res://scripts/build_profile.gd").release_build()
	conversation = "苔苔：欢迎回到这间小屋。"
	letter_index = 0
	tab = "手记"
	room_key = ""
	worn_outfit = ""
	life_panel.hide()
	postcard_view.hide()
	parcel_view.hide()
	home_interactions.book_panel.hide()
	home_interactions.moving = false
	refresh()
	notice.text = world.warning if not world.warning.is_empty() else "这间小屋的生活已经接着走了。"

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and world != null and not qa_mode:
		world.persist()




