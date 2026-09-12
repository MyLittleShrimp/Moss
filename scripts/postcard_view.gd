extends Control
const Art = preload("res://scripts/item_art.gd")
var host
var picture: TextureRect
var heading: Label
var message: Label
var wish: Label
var stamp: Label
var close_button: Button
var photo_button: Button
var text_side: VBoxContainer
var large = false
func _init(owner_node) -> void:
	host = owner_node
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.12, 0.18, 0.14, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var paper = Panel.new()
	paper.position = Vector2(100, 95)
	paper.size = Vector2(1240, 710)
	paper.add_theme_stylebox_override("panel", host.box(Color("fffaea"), 16))
	add_child(paper)
	var border = Control.new()
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.draw.connect(func():
		for i in range(40):
			var color = Color("aebca5") if i % 2 == 0 else Color("cea998")
			border.draw_line(Vector2(120 + i * 30, 108), Vector2(135 + i * 30, 108), color, 3, true)
			border.draw_line(Vector2(120 + i * 30, 792), Vector2(135 + i * 30, 792), color, 3, true)
		if not large: border.draw_line(Vector2(721, 146), Vector2(721, 697), Color("ddd4b9"), 1, true))
	add_child(border)
	resized.connect(func(): border.queue_redraw())
	picture = TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(picture)
	text_side = VBoxContainer.new()
	text_side.position = Vector2(740, 138)
	text_side.size = Vector2(550, 555)
	text_side.add_theme_constant_override("separation", 14)
	add_child(text_side)
	heading = text("", 29)
	stamp = text("", 16)
	text("寄给：在小屋等我的你", 20)
	message = text("", 21)
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wish = text("", 22)
	text("苔苔 敬上  ·  把这份风景也送给你", 17)
	photo_button = host.button_at("只看风景 / 返回明信片", Rect2(140, 735, 420, 44), func(): large = not large; layout_card())
	photo_button.reparent(self)
	close_button = host.button_at("收回相册 ×", Rect2(1090, 735, 200, 44), func(): hide())
	close_button.reparent(self)
	hide()
func text(value: String, size: int) -> Label:
	var label = Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", host.INK)
	label.add_theme_font_size_override("font_size", size)
	text_side.add_child(label)
	return label
func open(id: String) -> void:
	var card = host.world.postcard_content(id)
	if card.is_empty(): return
	picture.texture = Art.postcard(id)
	heading.text = "来自 " + card.title + " 的明信片"
	stamp.text = "◉ 旅行邮戳   " + card.date + "\n" + card.trip + "  ·  AI 预绘风景 / 本地旅行手记"
	message.text = card.text
	wish.text = card.wish
	large = false
	layout_card()
	show()
func layout_card() -> void:
	picture.position = Vector2(140, 125)
	picture.size = Vector2(580, 590) if not large else Vector2(1150, 590)
	text_side.visible = not large
	for node in get_children(): node.queue_redraw()
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		get_viewport().set_input_as_handled()
