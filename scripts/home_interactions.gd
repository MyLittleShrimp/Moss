extends Control
const Art = preload("res://scripts/item_art.gd")
const Home = preload("res://scripts/living_world.gd")
const SPOTS = {"window": Vector2(202, 302), "desk": Vector2(452, 305), "door": Vector2(651, 356)}
const HINTS = {"window": Vector2(157, 308), "desk": Vector2(470, 320), "door": Vector2(648, 360)}
var host
var pot: TextureRect
var pot_button: Button
var pot_hint: Button
var book_button: Button
var broom_button: Button
var rug_button: Button
var weather_label: Label
var moving = false
var destinations: Array[Button] = []
var book_panel: PanelContainer
var book_text: Label
var book_next: Button
var book_previous: Button
var book_close: Button
var clock_time = 0.0
var sweep_start = -100.0
var broom: Node2D
var pot_hide: Button
var book_source: Label
var book_client
var book_loading = false
var weather_canvas

func _init(owner_node) -> void:
	host = owner_node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather_canvas = load("res://scripts/weather_scene.gd").new()
	add_child(weather_canvas)
	pot = TextureRect.new()
	pot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pot.size = Vector2(80, 80)
	# Plant is now painted into the full room; this node only stores hit geometry.
	pot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pot)
	pot_button = button("移动盆栽", Rect2(170, 306, 95, 28), select_pot)
	pot_hint = button("移动 / 换盆栽", Rect2(170, 306, 110, 28), select_pot)
	pot_hide = button("收起盆栽", Rect2(170, 338, 110, 28), func():
		host.act("decorate", {"item": "plant"})
		moving = false
		refresh())
	object_style(pot_button)
	book_button = button("翻翻小书", Rect2(364, 286, 80, 43), func(): open_book(host.world.data.book_page))
	object_style(book_button)
	button("翻翻小书", Rect2(349, 329, 102, 29), func(): open_book(host.world.data.book_page))
	broom_button = button("扫扫地", Rect2(559, 426, 97, 29), sweep)
	var broom_object = button("扫帚", Rect2(578, 348, 46, 75), sweep)
	object_style(broom_object)
	rug_button = button("换张地毯", Rect2(316, 640, 105, 29), func(): host.life_panel.open("小屋"))
	weather_label = Label.new()
	weather_label.position = Vector2(762, 144)
	weather_label.size = Vector2(248, 45)
	weather_label.add_theme_color_override("font_color", Color("f8f7e8"))
	weather_label.add_theme_color_override("font_shadow_color", Color("405247"))
	weather_label.add_theme_constant_override("shadow_offset_y", 2)
	weather_label.add_theme_font_size_override("font_size", 16)
	weather_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(weather_label)
	for id in SPOTS:
		var spot_id = id
		var choice = button("放在" + Home.SPOTS[id], Rect2(HINTS[id], Vector2(130, 34)), func():
			host.act("plant_move", {"item": spot_id})
			moving = false
			refresh())
		choice.hide()
		destinations.append(choice)
	broom = load("res://scripts/sweep_brush.gd").new()
	add_child(broom)
	book_client = load("res://scripts/player_ai.gd").new()
	add_child(book_client)
	build_book()
	refresh()

func object_style(node: Button) -> void:
	node.tooltip_text = node.text
	node.text = ""
	node.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var hover = host.box(Color(0.96, 0.96, 0.83, 0.16), 14)
	hover.set_border_width_all(1)
	hover.border_color = Color(0.91, 0.91, 0.70, 0.6)
	node.add_theme_stylebox_override("hover", hover)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func button(text: String, rect: Rect2, callback: Callable) -> Button:
	var node = Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", 13)
	node.add_theme_stylebox_override("normal", host.box(Color(0.98, 0.97, 0.9, 0.86), 10))
	node.add_theme_stylebox_override("hover", host.box(Color("dce8cf"), 10))
	node.add_theme_color_override("font_color", host.INK)
	node.add_theme_color_override("font_hover_color", host.INK)
	node.pressed.connect(callback)
	add_child(node)
	return node

func select_pot() -> void:
	if "plant" not in host.world.data.equipped:
		host.life_panel.open("小屋" if "plant" in host.world.data.decorations else "小铺")
		return
	moving = not moving
	host.notice.text = "选一个摆放位置。想换盆栽，可在「小屋」里挑选。" if moving else "盆栽就在这里，慢慢长大。"
	refresh()

func sweep() -> void:
	var result = host.world.command("sweep")
	host.notice.text = result.message
	if result.ok: animate_sweep()
	host.refresh()

func animate_sweep() -> void:
	sweep_start = clock_time

func build_book() -> void:
	book_panel = PanelContainer.new()
	book_panel.position = Vector2(285, 230)
	book_panel.size = Vector2(600, 410)
	var style = host.box(Color("fff8df"), 20)
	style.set_border_width_all(2)
	style.border_color = Color("c8b98c")
	book_panel.add_theme_stylebox_override("panel", style)
	add_child(book_panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	book_panel.add_child(column)
	book_text = Label.new()
	book_text.custom_minimum_size = Vector2(545, 280)
	book_text.add_theme_color_override("font_color", host.INK)
	book_text.add_theme_font_size_override("font_size", 22)
	book_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	book_source = Label.new()
	book_source.add_theme_font_size_override("font_size", 14)
	book_source.add_theme_color_override("font_color", host.MUTED)
	column.add_child(book_source)
	book_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(book_text)
	var row = HBoxContainer.new()
	column.add_child(row)
	book_previous = book_nav(row, "← 上一页", func(): open_book(host.world.data.book_page - 1))
	book_next = book_nav(row, "下一页 →", func(): open_book(host.world.data.book_page + 1))
	book_close = book_nav(row, "合上小书", func(): book_panel.hide())
	book_panel.hide()

func book_nav(parent: Node, title: String, callback: Callable) -> Button:
	var node = Button.new()
	node.text = title
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size.y = 42
	node.add_theme_stylebox_override("normal", host.box(Color("e6dcc1")))
	node.add_theme_color_override("font_color", host.INK)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func open_book(page: int) -> void:
	var day = host.world.today()
	if host.world.data.daily_book.get("day") != day: page = 0
	host.world.ensure_book(day)
	var result = host.world.command("read_book", {"page": page})
	if not result.ok: return
	book_panel.show()
	moving = false
	render_book()
	host.refresh()
	if host.ai_client.enabled and not host.ai_client.busy and not book_loading and host.world.begin_book_attempt():
		book_loading = true
		book_client.copy_configuration(host.ai_client)
		book_client.enabled = true
		var epoch = int(host.world.data.memory_epoch)
		var requesting_world = host.world
		render_book()
		var reply = await book_client.reply("请为今天写一篇温柔、有一点意外的三页小故事。", host.ai_facts(), "daily_book")
		book_loading = false
		if host.world == requesting_world and reply.ok and host.ai_client.enabled: host.world.finish_book(day, epoch, reply.text)
		render_book()

func render_book() -> void:
	var book = host.world.data.daily_book
	if book.is_empty(): return
	var page = int(host.world.data.book_page)
	book_text.text = book.pages[page] + "\n\n— %d / 3 —" % (page + 1)
	book_source.text = book.day + " · " + ("正在写今天的小故事…" if book_loading else ("AI 生成 · 今日已保存" if book.source == "llm" else ("今日离线小故事 · AI 暂不可用" if book.attempted else "今日离线小故事 · 开启 AI 后可生成")))
	book_previous.disabled = page == 0
	book_next.disabled = page == 2

func refresh() -> void:
	var data = host.world.data
	pot.texture = Art.texture(Home.PLANTS[data.plant_style].art)
	pot.position = SPOTS[data.plant_spot] - Vector2(40, 68)
	pot.visible = false
	var has_plant = "plant" in data.equipped
	pot_hide.position = HINTS[data.plant_spot] + Vector2(0, 32)
	pot_hide.visible = has_plant
	pot_button.visible = has_plant
	pot_button.position = pot.position
	pot_button.size = pot.size
	pot_hint.position = HINTS[data.plant_spot]
	pot_hint.visible = not moving
	pot_hide.visible = has_plant and not moving
	pot_hint.text = "移动 / 换盆栽" if has_plant else "添一盆绿意"
	for choice in destinations: choice.visible = moving
	weather_label.text = "%s  ·  湿度 %d%%\n小屋模拟天气" % [Home.WEATHER_NAMES[data.weather.kind], data.weather.humidity]
	weather_canvas.state = data

func _process(delta: float) -> void:
	clock_time += delta
	var time = clock_time - sweep_start
	broom.visible = time < 1.8
	if broom.visible:
		broom.position = Vector2(450 + sin(time * 11) * 42, 532 + time * 22)
		broom.rotation = sin(time * 11) * 0.24

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (moving or book_panel.visible):
		moving = false
		book_panel.hide()
		refresh()
		get_viewport().set_input_as_handled()

