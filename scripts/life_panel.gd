extends Control
const Content = preload("res://scripts/game_content.gd")
const Art = preload("res://scripts/item_art.gd")
const Home = preload("res://scripts/living_world.gd")
const Rewards = preload("res://scripts/reward_world.gd")
var host
var page = "田园"
var crop = "herb"
var destination = "creek"
var food = "herb_box"
var provisions = {}
var pinned: VBoxContainer
var departure_summary: Label
var departure_button: Button
var bring_snack = false
var body: VBoxContainer
var feedback: Label
var actions: Dictionary = {}
var scroll: ScrollContainer
var tabs_by_name: Dictionary = {}

func _init(owner_node) -> void:
	host = owner_node

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.15, 0.20, 0.16, 0.50)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var card = Panel.new()
	card.position = Vector2(130, 78)
	card.size = Vector2(1180, 744)
	card.add_theme_stylebox_override("panel", host.box(Color("fbf8ee"), 24))
	add_child(card)
	var title = Label.new()
	title.text = "苔苔的生活手账"
	title.position = Vector2(161, 97)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", host.INK)
	add_child(title)
	var close = make_button("回到小屋 ×", func(): hide())
	close.position = Vector2(1107, 99)
	close.size = Vector2(165, 42)
	add_child(close)
	var tabs = HBoxContainer.new()
	tabs.position = Vector2(161, 158)
	tabs.size = Vector2(1116, 44)
	tabs.add_theme_constant_override("separation", 10)
	add_child(tabs)
	for title_text in ["田园", "厨房", "远行", "信箱", "收藏", "衣橱", "小铺", "小屋", "照料", "记忆"]:
		var button = make_button(title_text, func(): open(title_text))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		tabs_by_name[title_text] = button
	scroll = ScrollContainer.new()
	scroll.position = Vector2(161, 221)
	scroll.size = Vector2(1116, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	pinned = VBoxContainer.new()
	pinned.position = Vector2(161, 221)
	pinned.size = Vector2(1116, 84)
	add_child(pinned)
	feedback = Label.new()
	feedback.position = Vector2(161, 757)
	feedback.size = Vector2(1116, 48)
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.add_theme_color_override("font_color", host.GREEN)
	add_child(feedback)
	hide()

func make_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size.y = 42
	button.add_theme_stylebox_override("normal", host.box(Color("ece7d7")))
	button.add_theme_stylebox_override("hover", host.box(Color("dce4cd")))
	button.add_theme_stylebox_override("pressed", host.box(Color("c8d8b9")))
	button.add_theme_color_override("font_color", host.INK)
	button.add_theme_color_override("font_hover_color", host.INK)
	button.add_theme_color_override("font_pressed_color", host.INK)
	button.add_theme_stylebox_override("disabled", host.box(Color("e3e3d7")))
	button.add_theme_color_override("font_disabled_color", Color("647361"))
	button.pressed.connect(callback)
	return button

func line(text: String, large: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", host.INK)
	label.add_theme_font_size_override("font_size", 22 if large else 17)
	body.add_child(label)
	return label

func action(text: String, verb: String, payload: Dictionary, id: String = "") -> Button:
	var button = make_button(text, func(): execute(verb, payload))
	body.add_child(button)
	actions[id if id != "" else verb] = button
	return button

func execute(verb: String, payload: Dictionary) -> void:
	host.act(verb, payload)
	if verb == "travel" and host.world.data.trip_end > 0: provisions.clear(); bring_snack = false
	feedback.text = host.notice.text
	rebuild()

func open(value: String) -> void:
	page = value
	show()
	feedback.text = "小屋会记得你的布置，旅程与作物也会在离线时继续。"
	scroll.scroll_vertical = 0
	rebuild()

func grid(columns: int) -> GridContainer:
	var node = GridContainer.new()
	node.columns = columns
	node.add_theme_constant_override("h_separation", 14)
	node.add_theme_constant_override("v_separation", 14)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(node)
	return node

func text_node(parent: Node, text: String, font_size: int = 16, muted: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", host.MUTED if muted else host.INK)
	parent.add_child(label)
	return label

func picture(parent: Node, texture: Texture2D, side: int = 88, transparent: bool = true) -> TextureRect:
	var image = TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.custom_minimum_size = Vector2(side, side)
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.texture = texture
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if transparent: image.material = Art.matte_material()
	parent.add_child(image)
	return image

func tile(parent: Node, art: String, title: String, details: String, button_text: String = "", callback: Callable = Callable(), id: String = "", selected: bool = false, destination_art: bool = false) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = host.box(Color("eef3e5") if selected else Color("fffdf7"), 18)
	style.set_border_width_all(2 if selected else 1)
	style.border_color = Color("a1b58a") if selected else Color("e6e1d1")
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)
	var thumbnail = picture(row, Art.postcard(art) if destination_art else Art.texture(art), 76 if parent is GridContainer and parent.columns >= 3 else 94, not destination_art)
	if destination_art and callback.is_valid():
		thumbnail.mouse_filter = Control.MOUSE_FILTER_STOP
		thumbnail.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		thumbnail.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed: callback.call())
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 5)
	row.add_child(info)
	text_node(info, title, 18)
	text_node(info, details, 14, true)
	if not button_text.is_empty():
		var button = make_button(button_text, callback)
		button.custom_minimum_size.y = 36
		button.add_theme_font_size_override("font_size", 15)
		column.add_child(button)
		if id != "": actions[id] = button
	return column

func command_tile(parent: Node, art: String, title: String, details: String, button_text: String, verb: String, payload: Dictionary, id: String) -> VBoxContainer:
	return tile(parent, art, title, details, button_text, func(): execute(verb, payload), id)

func rebuild() -> void:
	for title in tabs_by_name:
		tabs_by_name[title].add_theme_stylebox_override("normal", host.box(Color("dce4cd") if title == page else Color("ece7d7")))
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	actions.clear()
	for child in pinned.get_children(): pinned.remove_child(child); child.queue_free()
	pinned.hide()
	scroll.position.y = 221
	scroll.size.y = 520
	match page:
		"田园": garden_page()
		"厨房": kitchen_page()
		"远行": journey_page()
		"收藏": collection_page()
		"小铺": shop_page()
		"小屋": home_page()
		"照料": care_page()
		"记忆": memory_page()
		"衣橱": wardrobe_page()
		"信箱": mailbox_page()

func garden_page() -> void:
	var data = host.world.data
	line("四季的小田地  /  先挑种子，再选一块田", true)
	var choices = grid(4)
	for id in Content.CROPS:
		var seed_id = id
		var detail = Content.CROPS[id]
		tile(choices, id, detail.name, "%s成熟 · 收成 %d\n仓库 %d 份" % [host.world.Timing.duration_text(host.world.crop_seconds(id)), detail.yield, data.ingredients[id]], "✓ 已选种子" if crop == id else "选这包种子", func(): crop = seed_id; rebuild(), "seed_" + id, crop == id)
	line("你的三块田  ·  免费种子，成熟不枯萎")
	var plots = grid(3)
	for i in range(3):
		var end = float(data.plots[i])
		var growing = end > host.world.clock()
		var crop_id = crop if end == 0 else str(data.plot_crops[i])
		var info = "空田 · 等你播种" if end == 0 else ("慢慢长大 · 约 %d 秒" % ceili(end - host.world.clock()) if growing else "成熟了 · 可以收获")
		command_tile(plots, crop_id, "田地 %d · %s" % [i + 1, Content.CROPS[crop_id].name], info, "种下" + Content.CROPS[crop_id].name if end == 0 else ("看看生长情况" if growing else "收获这一份开心"), "garden", {"plot": i, "crop": crop}, "plot" + str(i))

func ready_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", host.box(host.GREEN))
	button.add_theme_stylebox_override("hover", host.box(Color("6e895d")))
	button.add_theme_color_override("font_color", host.PAPER)
	button.add_theme_color_override("font_hover_color", host.PAPER)

func kitchen_page() -> void:
	var data = host.world.data
	pinned.show()
	pinned.position.y = 221
	scroll.position.y = 307
	scroll.size.y = 434
	var basket = GridContainer.new()
	basket.columns = 4
	pinned.add_child(basket)
	for id in Content.CROPS:
		var cell = HBoxContainer.new()
		cell.custom_minimum_size.x = 274
		basket.add_child(cell)
		picture(cell, Art.texture(id), 32)
		text_node(cell, "%s  × %d" % [Content.CROPS[id].name, data.ingredients[id]], 17)
	var recipes = grid(2)
	for id in Content.FOODS:
		var meal = Content.FOODS[id]
		var enough = true
		var parts: Array[String] = []
		for ingredient in meal.recipe:
			if data.ingredients[ingredient] < meal.recipe[ingredient]: enough = false
			parts.append("%s %d/%d" % [Content.CROPS[ingredient].name, data.ingredients[ingredient], meal.recipe[ingredient]])
		command_tile(recipes, id, "%s   × %d" % [meal.name, data.foods[id]], "现有/需要：" + " · ".join(parts) + "\n补给 %d · 耐放 %d 级" % [meal.nutrition, meal.tier], "做一份 · " + meal.name if enough else "食材不足", "cook", {"food": id}, id)
		actions[id].disabled = not enough
		if enough: ready_button(actions[id])

func select_destination(id: String) -> void:
	destination = id
	for food_id in provisions.keys():
		if Content.FOODS[food_id].tier < Content.ROUTES[id].tier: provisions.erase(food_id)
	rebuild()

func update_provisions(id: String, quantity: float) -> void:
	if quantity > 0: provisions[id] = int(quantity)
	else: provisions.erase(id)
	update_departure()

func update_departure() -> void:
	var total = 0
	for id in provisions: total += int(provisions[id]) * int(Content.FOODS[id].nutrition)
	var route = Content.ROUTES[destination]
	var check = host.world.travel_check(destination, {"provisions":provisions, "snack":bring_snack})
	departure_summary.text = "%s  ·  耐放 ≥ %d 级  ·  补给 %d / %d%s" % [route.name, route.tier, total, route.supply, "  ·  已备齐" if check.ok else "  ·  " + check.message]
	departure_button.text = "装好行囊，出发 →" if host.world.data.trip_end == 0 else "苔苔在旅途中 · 归期未定"
	departure_button.disabled = not check.ok

func journey_page() -> void:
	var data = host.world.data
	for id in provisions.keys():
		provisions[id] = mini(int(provisions[id]), int(data.foods[id]))
		if provisions[id] == 0 or Content.FOODS[id].tier < Content.ROUTES[destination].tier: provisions.erase(id)
	if data.foods.berry_snack < 1: bring_snack = false
	line("下一封信，会从哪里寄来？", true)
	var routes = grid(3)
	for id in Content.ROUTES:
		var route_id = id
		var detail = Content.ROUTES[id]
		tile(routes, id, detail.name, "%s\n补给 %d · 耐放 %d 级" % [host.world.Timing.HINTS[id] if host.world.release_timing else detail.hint, detail.supply, detail.tier], "✓ 想去这里" if destination == id else "选这个目的地", func(): select_destination(route_id), "route_" + id, destination == id, true)
	line("自由搭配便当 · 每份均需达到耐放等级，补给相加；多带的食物也会消耗。")
	var meals = grid(3)
	for id in Content.FOODS:
		var meal = Content.FOODS[id]
		if meal.get("snack", false): continue
		var eligible = meal.tier >= Content.ROUTES[destination].tier
		var column = tile(meals, id, meal.name, "库存 %d · 每份补给 %d · 耐放 %d 级%s" % [data.foods[id], meal.nutrition, meal.tier, "\n耐放不足，不能携带" if not eligible else ""], "", Callable(), "", int(provisions.get(id,0)) > 0)
		var counter = SpinBox.new()
		counter.min_value = 0
		counter.max_value = mini(10000, int(data.foods[id])) if eligible and data.trip_end == 0 else 0
		counter.step = 1
		counter.value = provisions.get(id, 0)
		counter.editable = eligible and data.foods[id] > 0 and data.trip_end == 0
		counter.get_line_edit().add_theme_stylebox_override("normal", host.box(Color("edf0e4"), 8))
		counter.get_line_edit().add_theme_color_override("font_color", host.INK)
		counter.get_line_edit().add_theme_color_override("font_uneditable_color", host.MUTED)
		counter.suffix = "份"
		counter.custom_minimum_size.y = 42
		var counting = HBoxContainer.new()
		column.add_child(counting)
		var minus = make_button("−", func(): counter.value -= 1)
		minus.custom_minimum_size = Vector2(42,42)
		counting.add_child(minus)
		counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		counting.add_child(counter)
		var plus = make_button("＋", func(): counter.value += 1)
		plus.custom_minimum_size = Vector2(42,42)
		counting.add_child(plus)
		minus.disabled = not counter.editable or counter.value == 0
		plus.disabled = not counter.editable or counter.value >= counter.max_value
		counter.value_changed.connect(func(value): minus.disabled = not counter.editable or value == 0; plus.disabled = not counter.editable or value >= counter.max_value)
		counter.get_line_edit().add_theme_stylebox_override("read_only", host.box(Color("e3e4dd"), 8))
		counter.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_CENTER
		if not eligible or data.foods[id] == 0: column.modulate = Color("a6aaa2")
		var meal_id = id
		counter.value_changed.connect(func(value): update_provisions(meal_id, value))
		actions["count_" + id] = counter
	var snack = make_button(("✓ " if bring_snack else "+ ") + "额外带一包草莓点心（库存 %d）" % data.foods.berry_snack, func(): bring_snack = not bring_snack; rebuild())
	snack.disabled = data.foods.berry_snack < 1 or data.trip_end > 0
	body.add_child(snack)
	actions.snack = snack
	line("草莓点心：增加获得稀有物品的机会。额外带上一包，给旅途添一点甜。点心不替代主食。")
	var detail = Content.ROUTES[destination]
	line("当地回忆：%s · 隐藏收藏：%s" % [Content.ITEMS[detail.common].name if host.world.discovered(detail.common) else "未发现的纪念品", Content.ITEMS[detail.rare].name if host.world.discovered(detail.rare) else "神秘包裹 ?"])
	if host.world.release_timing:
		line("有些小小的宝物，藏在不经意的相遇里。")
		if destination in Content.LONG_ROUTES:
			line("远行会为旅册添上新的回忆。路上歇脚时，苔苔也会寄来消息。")
	else:
		line("此地最迟第%d次成功到访获得隐藏收藏；折返不计，绕路按实际到访地计。" % host.world.rare_guarantee(destination))
		if destination in Content.LONG_ROUTES:
			line("长旅旅册：已积累 %d 页，每次非折返完成行程添一页、得 %d 叶币；每 3 页完成一册，额外得 6 叶币。" % [data.get("travel_progress", {}).get(destination, 0), Content.PROGRESS_COINS[destination]])
			line("途中至少一封来信，正常长旅连续无消息不超过两天。忘带东西会提前折返，食物原样带回。")
	for item in Rewards.ROOM_REWARDS:
		if item in [detail.common, detail.rare]: line("小屋纪念奖励：" + (Rewards.ROOM_REWARDS[item].name if host.world.discovered(item) else "一件来自这里的神秘布置"))
	for outfit in Rewards.OUTFITS.values():
		if outfit.route == destination: line("旅行装扮目标：" + (outfit.name if host.world.discovered(outfit.item) else "一份神秘衣饰，等发现后再揭晓"))
	if not host.world.release_timing:
		action("节奏：" + {"normal":"正常测试", "demo":"体验加速", "balanced":"正式节奏 ×60"}[data.pace] + " · 点击切换（仅新播种／出发）", "pace", {"pace":{"normal":"demo", "demo":"balanced", "balanced":"normal"}[data.pace]}, "pace")
	pinned.position.y = 657
	pinned.show()
	scroll.size.y = 422
	departure_summary = text_node(pinned, "", 18)
	departure_button = make_button("", func(): execute("travel", {"destination":destination, "provisions":provisions.duplicate(true), "snack":bring_snack}))
	departure_button.custom_minimum_size.y = 50
	departure_button.add_theme_font_size_override("font_size", 22)
	ready_button(departure_button)
	pinned.add_child(departure_button)
	actions.travel = departure_button
	update_departure()

func collection_page() -> void:
	var data = host.world.data
	line("从远方带回的小小世界  ·  %d / 9 明信片" % data.postcards.size(), true)
	if not data.pending_discoveries.is_empty():
		var parcel = make_button("拆开旅行包裹 · %d 个新发现" % data.pending_discoveries.size(), func(): host.parcel_view.open())
		body.add_child(parcel)
		actions.parcel = parcel
	line("点开明信片看大图与寄语。旅行宝物还会解锁衣橱和小屋奖励，第一件纪念品永久保留。")
	var wardrobe_button = make_button("看看旅行解锁的衣橱 →", func(): open("衣橱"))
	body.add_child(wardrobe_button)
	var collection = grid(2)
	for id in Content.ROUTES:
		var route = Content.ROUTES[id]
		var unlocked = id in data.postcards
		var destination_id = id
		var column = tile(collection, id if unlocked else "unknown", route.name, "已到访 · 一封远方的信" if unlocked else "明信片尚未寄到", "展开明信片 ↗" if unlocked else "", func(): host.postcard_view.open(destination_id), "postcard_" + id, false, unlocked)
		if id in Content.LONG_ROUTES:
			var pages = int(data.get("travel_progress", {}).get(id, 0))
			if host.world.release_timing:
				text_node(column, "旅册已留下 %d 页回忆" % pages if pages > 0 else "新的旅册，等一段远方的故事", 14)
			else:
				text_node(column, "旅册 %d 页 · 已完成 %d 册纪念章 · 下册 %d/3" % [pages, floori(pages / 3.0), pages % 3], 14)
		var row = HBoxContainer.new()
		column.add_child(row)
		var common_known = host.world.discovered(route.common)
		picture(row, Art.texture(route.common if common_known else "unknown"), 50)
		text_node(row, "%s × %d" % [Content.ITEMS[route.common].name, data.items.get(route.common, 0)] if common_known else "神秘纪念品\n?", 14)
		var discovered = host.world.discovered(route.rare)
		picture(row, Art.texture(route.rare if discovered else "unknown"), 50)
		text_node(row, "%s × %d" % [Content.ITEMS[route.rare].name, data.items.get(route.rare, 0)] if discovered else "隐藏宝物\n尚未发现", 14)
	line("把旅行成果带进小屋", true)
	line("领取不消耗收藏，也不花叶币。已买过同款也会保留；不会折算为重复金币。")
	var gifts = grid(2)
	for id in Rewards.ROOM_REWARDS:
		var gift_id = id
		var gift = Rewards.ROOM_REWARDS[id]
		var found = host.world.discovered(id)
		var claimed = id in data.claimed_room_rewards
		tile(gifts, id if found else "unknown", gift.name if found else "神秘小屋布置", "发现" + Content.ITEMS[id].name + "后解锁" if found else "从旅行包裹中发现", "去小屋摆放" if claimed else ("领取小屋奖励" if found else "尚未发现"), func():
			if gift_id in host.world.data.claimed_room_rewards: open("小屋")
			else: execute("claim_room_reward", {"item": gift_id}), "gift_" + id)
		actions["gift_" + id].disabled = not found
	action("把溪边青石摆在窗台" if host.world.discovered("stone") else "窗台纪念品 · 尚未发现", "place", {}, "collection_stone").disabled = not host.world.discovered("stone")

func wardrobe_page() -> void:
	line("把走过的路，穿在身上", true)
	line("找到宝物即永久解锁；换装不花钱、不消耗收藏。每次穿一套，也能随时换回最初的样子。")
	var clothes = grid(3)
	for id in Rewards.OUTFITS:
		var outfit_id = id
		var outfit = Rewards.OUTFITS[id]
		var unlocked = host.world.outfit_unlocked(id)
		var panel = PanelContainer.new()
		panel.add_theme_stylebox_override("panel", host.box(Color("e7efdc") if host.world.data.outfit == id else Color("fffdf7"), 16))
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		clothes.add_child(panel)
		var column = VBoxContainer.new()
		column.add_theme_constant_override("separation", 8)
		panel.add_child(column)
		var texture = load("res://assets/frog.png" if id == "plain" or not unlocked else "res://assets/outfits/" + id + ".png")
		var portrait = picture(column, texture, 150, false)
		if not unlocked:
			var shader = Shader.new()
			shader.code = "shader_type canvas_item; void fragment(){ COLOR=vec4(vec3(0.64,0.67,0.62),texture(TEXTURE,UV).a); }"
			var silhouette = ShaderMaterial.new()
			silhouette.shader = shader
			portrait.material = silhouette
			var question = Label.new()
			question.text = "?"
			question.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			question.add_theme_font_size_override("font_size", 48)
			question.add_theme_color_override("font_color", Color("fffdf7"))
			portrait.add_child(question)
		text_node(column, outfit.name if unlocked else "神秘衣饰", 21)
		text_node(column, outfit.note if unlocked else "拆开包裹后，才知道它的样子", 16, true)
		text_node(column, "初始装扮" if id == "plain" else "探索地点：" + Content.ROUTES[outfit.route].name, 15)
		var wear = make_button("✓ 正在穿戴" if host.world.data.outfit == id else ("换上这套" if unlocked else "尚未解锁"), func(): execute("wear", {"item": outfit_id}))
		wear.disabled = not unlocked
		column.add_child(wear)
		actions["wear_" + id] = wear

func shop_page() -> void:
	var data = host.world.data
	line("叶子小铺  /  叶币 %d" % data.coins, true)
	line("把重复的纪念品换成下一次出发，第一件会留下。")
	var duplicates = grid(3)
	for id in Content.ITEMS:
		if int(data.items.get(id, 0)) > 1 and host.world.discovered(id): command_tile(duplicates, id, Content.ITEMS[id].name, "拥有 %d · 保留首件" % data.items[id], "兑换 1 件 · +%d 叶币" % Content.ITEMS[id].value, "sell", {"item": id}, "sell_" + id)
	line("厨房补给", true)
	var goods = grid(3)
	for id in Content.CROPS: command_tile(goods, id, Content.CROPS[id].name, "仓库 %d 份" % data.ingredients[id], "买一份 · %d 叶币" % Content.CROP_PRICES[id], "buy", {"kind": "crop", "item": id}, "buy_" + id)
	for id in Content.FOODS: command_tile(goods, id, Content.FOODS[id].name, "库存 %d · 补给 %d" % [data.foods[id], Content.FOODS[id].nutrition], "买一份 · %d 叶币" % Content.food_price(id), "buy", {"kind": "food", "item": id}, "buy_" + id)
	line("给小屋添一点喜欢", true)
	var furniture = grid(3)
	for id in Content.DECOR:
		if Content.DECOR[id].get("reward_only", false): continue
		if id not in data.decorations: command_tile(furniture, id, Content.DECOR[id].name, "购买后即可摆放", "%d 叶币 · 带回小屋" % Content.DECOR[id].price, "buy", {"kind": "decor", "item": id}, "buy_" + id)
	if "flower" not in data.plant_styles: command_tile(furniture, "flower", "春日花盆", "含花盆，可移动或换回绿植", "12 叶币 · 换一盆花", "home_buy", {"kind": "plant", "item": "flower"}, "buy_flower")
	for id in Home.RUGS:
		if id not in data.rugs: command_tile(furniture, id, Home.RUGS[id].name, "更换小屋地毯", "%d 叶币 · 换上新毯" % Home.RUGS[id].price, "home_buy", {"kind": "rug", "item": id}, "buy_" + id)
	for id in Content.THEMES:
		if id not in data.themes: command_tile(furniture, "flower", Content.THEMES[id], "季节氛围 · 随时更换", "10 叶币 · 收藏季节", "buy", {"kind": "theme", "item": id}, "buy_" + id)

func home_page() -> void:
	var data = host.world.data
	line("把小屋，住成喜欢的样子", true)
	line("回到场景，点盆栽再选位置；点书翻页，点扫帚扫地。")
	if "plant" in data.equipped: action("收起盆栽 · 留一点空白", "decorate", {"item": "plant"}, "hide_plant")
	var plants = grid(3)
	for id in data.plant_styles: command_tile(plants, Home.PLANTS[id].art, Home.PLANTS[id].name, "摆在" + Home.SPOTS[data.plant_spot], "✓ 正在摆放" if data.plant_style == id and "plant" in data.equipped else "换这盆植物", "plant_style", {"item": id}, "plant_" + id)
	for id in data.plant_styles:
		actions["plant_" + id].disabled = "plant" not in data.decorations
		if "plant" not in data.decorations: actions["plant_" + id].text = "先在小铺带回一盆植物"
	command_tile(plants, "stone", "窗台上的青石", "一段溪边的回忆", "已经安放" if data.placed else "摆上窗台", "place", {}, "place")
	line("地毯与装饰")
	var furniture = grid(3)
	for id in data.rugs: command_tile(furniture, id, Home.RUGS[id].name, "柔软地留住脚步", "✓ 已铺好" if data.rug == id else "铺上这张地毯", "rug", {"item": id}, "rug_" + id)
	for id in data.decorations:
		if id == "plant": continue # The plant style and placement above control this same object.
		command_tile(furniture, id, Content.DECOR[id].name, "随时收起或再摆出来", "收起" if id in data.equipped else "摆放", "decorate", {"item": id}, id)
	for id in data.themes: action(("✓ " if id == data.theme else "换上") + Content.THEMES[id], "theme", {"item": id}, id)

func care_page() -> void:
	var data = host.world.data
	line("慢一点，也很好", true)
	var care = grid(2)
	command_tile(care, "herb_box" if data.condition == "ill" else "book", {"well": "苔苔精神不错", "ill": "有点着凉", "mood": "想安静坐一会儿"}[data.condition], "一碗香草汤，或一会儿陪伴。\n休息后也会自然恢复。", "煮汤 · 香草 1 份" if data.condition == "ill" else "陪它坐一会儿", "care", {}, "care")
	command_tile(care, "broom", "给小屋扫扫地", "整洁度 %d%% · 不影响奖励\n想起时做一点，就很好。" % data.cleanliness, "沙沙 · 扫掉落叶", "sweep", {}, "sweep")
	line("窗外：%s · 湿度 %d%%（小屋模拟天气）" % [Home.WEATHER_NAMES[data.weather.kind], data.weather.humidity])
	for event in data.events.slice(0, 4): line("· " + event.text)

func memory_page() -> void:
	line("一起慢慢长大的记忆本", true)
	line("写下你的喜好，也可以聊天说“我喜欢……”或“我不喜欢……”。相同主题会更新，随时能忘记。")
	var row = HBoxContainer.new()
	body.add_child(row)
	var value = OptionButton.new()
	value.add_item("我喜欢")
	value.add_item("我不喜欢")
	value.add_theme_color_override("font_color", host.INK)
	value.add_theme_stylebox_override("normal", host.box(Color("ece7d7")))
	value.add_theme_stylebox_override("hover", host.box(Color("dce4cd")))
	row.add_child(value)
	var topic = LineEdit.new()
	topic.name = "PreferenceTopic"
	topic.max_length = 40
	topic.placeholder_text = "例如：茉莉花、安静的海边、羽生结弦"
	topic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topic.add_theme_color_override("font_color", host.INK)
	topic.add_theme_color_override("font_placeholder_color", host.MUTED)
	topic.add_theme_stylebox_override("normal", host.box(Color("eee9d9")))
	topic.add_theme_stylebox_override("focus", host.box(Color("e4ebd9")))
	row.add_child(topic)
	var save = make_button("记住这件小事", func(): execute("preference_set", {"topic": topic.text, "value": "like" if value.selected == 0 else "dislike"}))
	row.add_child(save)
	actions.memory_save = save
	line("你亲口告诉它的偏好  ·  %d / 32" % host.world.data.preferences.size(), true)
	for name in host.world.data.preferences:
		var entry = host.world.data.preferences[name]
		line(("喜欢" if entry.value == "like" else "不喜欢") + name + "\n来自：" + entry.source)
		action("忘记“" + name + "”", "preference_remove", {"topic": name}, "forget_" + name)
	line("相处留下的足迹", true)
	line("这些是发生过的游玩记录，不会自动当成你的个人喜好。开启 AI 后，偏好与近期足迹会用于对话和今日小书。")
	var notes = host.world.observations()
	line("再一起种点东西、走走看看吧。" if notes.is_empty() else "\n".join(notes))
	action("清空生活足迹", "clear_observations", {}, "clear_habits")
	line("忘记后不再用于新内容；已保存的小书和旅行信不会重写。")

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()




func mailbox_page() -> void:
	line("把路上的小日子，寄回给你", true)
	line("多城慢游途中可能寄来信件和明信片；寄出顺序跟随途经城市，每站每趟最多一封，偶尔也会没来得及寄。离线来信会保留。")
	var mail = host.world.data.get("travel_mail", [])
	if mail.is_empty():
		line("信箱还安安静静的。等下一次长途远行，苔苔会把沿途见闻寄回来。")
		return
	var cards = grid(2)
	for entry in mail:
		var letter = entry
		var title = ("未读 · " if not entry.read else "已读 · ") + ("旅途报平安" if entry.get("reassurance", false) else host.world.Mail.city_name(entry.destination))
		var date = Time.get_date_string_from_unix_time(int(entry.time))
		tile(cards, entry.destination if entry.kind == "postcard" else "mail", title, "%s · 第%d次远行\n%s" % [date, entry.trip, "一张途中明信片" if entry.kind == "postcard" else "一封途中来信"], "展开阅读", func(): host.postcard_view.open_mail(letter); rebuild(), "mail_" + entry.id, false, entry.kind == "postcard")


