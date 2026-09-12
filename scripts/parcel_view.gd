extends Control
const Art = preload("res://scripts/item_art.gd")
const Rewards = preload("res://scripts/reward_world.gd")
var host
var picture: TextureRect
var title: Label
var detail: Label
var open_button: Button
var use_button: Button
var close_button: Button
var current = ""
var animating = false
func _init(owner_node) -> void:
	host = owner_node
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.12, 0.18, 0.14, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var paper = Panel.new()
	paper.position = Vector2(400, 165)
	paper.size = Vector2(640, 580)
	paper.add_theme_stylebox_override("panel", host.box(Color("fff9e9"), 24))
	add_child(paper)
	title = label("远方寄回的小惊喜", Rect2(435, 195, 570, 65), 28)
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.position = Vector2(610, 280)
	picture.size = Vector2(220, 220)
	picture.pivot_offset = Vector2(110, 110)
	add_child(picture)
	detail = label("", Rect2(435, 510, 570, 85), 19)
	open_button = host.button_at("解开绳结，看看里面", Rect2(460, 615, 520, 42), reveal, true)
	open_button.reparent(self)
	use_button = host.button_at("", Rect2(460, 666, 250, 42), use_reward)
	use_button.reparent(self)
	close_button = host.button_at("先收好", Rect2(730, 666, 250, 42), func(): if not animating: hide())
	close_button.reparent(self)
	hide()
func label(value: String, rect: Rect2, size: int) -> Label:
	var node = Label.new()
	node.text = value
	node.position = rect.position
	node.size = rect.size
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", host.INK)
	add_child(node)
	return node
func open() -> void:
	if host.world.data.pending_discoveries.is_empty(): return
	current = ""
	title.text = "远方寄回的小惊喜"
	detail.text = "它把一路上的发现，小心装进了包裹。\n解开之前，先猜猜是什么？"
	picture.texture = Art.texture("unknown")
	picture.material = null
	picture.scale = Vector2.ONE
	open_button.text = "解开绳结，看看里面"
	open_button.disabled = false
	use_button.hide()
	show()
func reveal() -> void:
	if animating: return
	if host.world.data.pending_discoveries.is_empty(): hide(); return
	animating = true
	open_button.disabled = true
	var tween = create_tween()
	tween.tween_property(picture, "scale", Vector2(0.85, 0.85), 0.14)
	await tween.finished
	var result = host.world.command("reveal_next")
	if result.ok:
		if host.audio_manager != null: host.audio_manager.play_cue("discover")
		current = result.item
		title.text = "新发现 · " + GameContent.ITEMS[current].name
		picture.texture = Art.texture(current)
		picture.material = Art.matte_material()
		detail.text = "一份来自远方的纪念，已经放进收藏。"
		use_button.text = "看看收藏"
		for outfit in Rewards.OUTFITS.values():
			if outfit.item == current: detail.text = "解锁新装扮 · " + outfit.name; use_button.text = "试穿一下"
		if Rewards.ROOM_REWARDS.has(current): detail.text = "可领取小屋奖励 · " + Rewards.ROOM_REWARDS[current].name; use_button.text = "领取并去布置"
		use_button.show()
	var pop = create_tween()
	pop.tween_property(picture, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished
	animating = false
	open_button.text = "拆开下一件 · 还剩 %d 件" % host.world.data.pending_discoveries.size() if not host.world.data.pending_discoveries.is_empty() else "包裹拆完了，收好"
	open_button.disabled = false
	host.refresh()
	if host.life_panel.visible: host.life_panel.rebuild()
func use_reward() -> void:
	if animating: return
	if Rewards.ROOM_REWARDS.has(current):
		host.act("claim_room_reward", {"item": current})
		host.life_panel.open("小屋")
	else:
		var page = "收藏"
		for outfit in Rewards.OUTFITS.values():
			if outfit.item == current: page = "衣橱"
		host.life_panel.open(page)
	hide()
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if not animating: hide()
		get_viewport().set_input_as_handled()
