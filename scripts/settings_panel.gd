extends Control
const Profile = preload("res://scripts/build_profile.gd")
var host
var body: VBoxContainer
var feedback: Label
var url: LineEdit
var model_name: LineEdit
var key: LineEdit
var password: LineEdit
var remember: CheckBox
var slot_name: LineEdit
var save_list: ItemList
var slot_ids = []
var file_dialog: FileDialog
var actions = {}

func _init(owner_node) -> void:
	host = owner_node

func _ready() -> void:
	theme = host.theme.duplicate()
	for kind in ["Label", "LineEdit", "ItemList", "CheckBox", "Button"]:
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_selected_color"]:
			theme.set_color(color, kind, host.INK)
	theme.set_color("font_placeholder_color", "LineEdit", host.MUTED)
	theme.set_stylebox("normal", "LineEdit", host.box(Color("efeddf"), 8))
	theme.set_stylebox("focus", "LineEdit", host.box(Color("dce6ce"), 8))
	theme.set_stylebox("panel", "ItemList", host.box(Color("efeddf"), 10))
	theme.set_stylebox("selected", "ItemList", host.box(Color("dce6ce"), 6))
	theme.set_stylebox("selected_focus", "ItemList", host.box(Color("dce6ce"), 6))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.15, 0.20, 0.16, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel = Panel.new()
	panel.position = Vector2(150, 65)
	panel.size = Vector2(1140, 770)
	panel.add_theme_stylebox_override("panel", host.box(host.PAPER, 24))
	add_child(panel)
	var layout = VBoxContainer.new()
	layout.position = Vector2(185, 90)
	layout.size = Vector2(1070, 720)
	layout.add_theme_constant_override("separation", 14)
	add_child(layout)
	var top = HBoxContainer.new()
	layout.add_child(top)
	var heading = Label.new()
	heading.text = "小屋设置 · " + ("发布版慢生活" if Profile.release_build() else "内部开发版")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_font_size_override("font_size", 27)
	top.add_child(heading)
	button(top, "回到小屋 ×", func(): hide(), "close")
	var tabs = HBoxContainer.new()
	layout.add_child(tabs)
	button(tabs, "我的 AI 模型", ai_page, "ai_tab")
	button(tabs, "存档与搬家", saves_page, "save_tab")
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 550
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)
	feedback = Label.new()
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.y = 44
	layout.add_child(feedback)
	file_dialog = FileDialog.new()
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.json ; 小屋便携存档"])
	file_dialog.use_native_dialog = true
	file_dialog.file_selected.connect(file_selected)
	add_child(file_dialog)
	hide()

func button(parent: Node, title: String, callback: Callable, id: String = "") -> Button:
	var node = Button.new()
	node.text = title
	node.custom_minimum_size.y = 42
	node.add_theme_stylebox_override("normal", host.box(Color("e7eadb"), 10))
	node.add_theme_stylebox_override("hover", host.box(Color("d6e1c5"), 10))
	node.add_theme_color_override("font_color", host.INK)
	node.pressed.connect(callback)
	parent.add_child(node)
	if not id.is_empty(): actions[id] = node
	return node

func label(text: String) -> void:
	var node = Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(node)

func field(title: String, value: String = "", secret: bool = false) -> LineEdit:
	var row = HBoxContainer.new()
	body.add_child(row)
	var name_label = Label.new()
	name_label.text = title
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	var node = LineEdit.new()
	node.text = value
	node.secret = secret
	node.custom_minimum_size.y = 38
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(node)
	return node

func clear_body() -> void:
	for node in body.get_children(): body.remove_child(node); node.queue_free()
	feedback.text = ""

func open() -> void:
	host.life_panel.hide()
	show()
	move_to_front()
	ai_page()

func ai_page() -> void:
	clear_body()
	label("选择自己的模型。启用 AI 后，对话、小书会发送相关游戏上下文；关闭后仍可离线游玩。")
	var presets = HBoxContainer.new()
	body.add_child(presets)
	button(presets, "本机 Ollama", func(): url.text = "http://127.0.0.1:11434/v1/chat/completions"; model_name.text = ""; key.text = ""; remember.button_pressed = false)
	button(presets, "DeepSeek（自备 Key）", func(): url.text = "https://api.deepseek.com/chat/completions"; model_name.text = "deepseek-chat"; key.text = ""; remember.button_pressed = false)
	button(presets, "自定义兼容接口", func(): url.text = ""; model_name.text = ""; key.text = ""; remember.button_pressed = false)
	url = field("完整接口地址", host.ai_client.endpoint)
	url.placeholder_text = "https://服务商/v1/chat/completions"
	model_name = field("模型名称", host.ai_client.model)
	model_name.placeholder_text = "填写服务商模型 ID，或 ollama list 中的模型名称"
	key = field("API Key", host.ai_client.api_key, true)
	key.placeholder_text = "本机 Ollama 通常留空；云端填写自己的 Key"
	remember = CheckBox.new()
	remember.text = "在本机加密保存 Key（下次启动需口令解锁）"
	body.add_child(remember)
	password = field("密钥解锁口令", "", true)
	password.placeholder_text = "至少8位；不保存口令，忘记后可重新填写 Key"
	label("默认只在本次运行保留 Key。模型设置不进入游戏存档；连接测试仅发送固定虚构问候。")
	var row = HBoxContainer.new()
	body.add_child(row)
	button(row, "保存配置", save_ai, "save_ai")
	button(row, "解锁已保存 Key", unlock_key, "unlock")
	button(row, "测试连接", test_ai, "test_ai")

func save_ai() -> void:
	if host.home_interactions.book_loading: feedback.text = "请等小书生成结束再修改配置。"; return
	var problem = host.ai_client.configure(url.text, model_name.text, key.text, remember.button_pressed, password.text)
	feedback.text = "已保存。回小屋勾选“启用 AI 对话”即可使用。" if problem.is_empty() else problem
	password.text = ""

func unlock_key() -> void:
	if host.ai_client.busy: feedback.text = "请等当前请求结束。"; return
	var success = host.ai_client.unlock(password.text)
	password.text = ""
	if success: key.text = host.ai_client.api_key
	feedback.text = "Key 已解锁，仅在本次运行使用。" if success else "解锁失败：请检查口令或重新填写自己的 Key。"

func test_ai() -> void:
	if host.ai_client.busy or host.home_interactions.book_loading: feedback.text = "请等当前请求结束。"; return
	if url.text != host.ai_client.endpoint or model_name.text != host.ai_client.model or key.text != host.ai_client.api_key:
		feedback.text = "请先保存填写的配置，再测试连接。"; return
	feedback.text = "正在测试，首次加载本机模型可能较慢…"
	var result = await host.ai_client.test_connection()
	feedback.text = "连接成功，模型返回了有效问候。" if result.ok else host.ai_client.status_text

func saves_page() -> void:
	clear_body()
	label("当前生活持续自动保存。另存会创建独立副本并切换过去；新建不会覆盖旧档。")
	label("当前：" + str(host.world.data.get("slot_title", "旧小屋")) + " · " + ("发布版目录" if Profile.release_build() else "开发版目录"))
	slot_name = field("新档 / 副本名称", "我的另一间小屋")
	save_list = ItemList.new()
	save_list.custom_minimum_size.y = 180
	body.add_child(save_list)
	slot_ids.clear()
	for slot in host.save_library.slots():
		slot_ids.append(slot.id)
		save_list.add_item(("● " if slot.id == host.save_library.active else "○ ") + slot.title)
	var row = HBoxContainer.new()
	body.add_child(row)
	button(row, "立即保存", func(): feedback.text = "已保存当前生活。" if host.world.persist() and not host.world.save_path.is_empty() else "当前为临时生活，请另存。", "save_now")
	button(row, "另存为新档", func(): change_save("copy"), "save_as")
	button(row, "新建生活", func(): change_save("new"), "new_save")
	button(row, "加载选中存档", func(): change_save("load"), "load_save")
	var transfer = HBoxContainer.new()
	body.add_child(transfer)
	button(transfer, "导出当前存档…", func(): choose_file(true), "export")
	button(transfer, "导入存档为新档…", func(): choose_file(false), "import")
	button(transfer, "打开存档文件夹", func(): OS.shell_open(ProjectSettings.globalize_path(host.save_library.directory)))
	label("换电脑：导出 JSON → 复制文件 → 新电脑导入。离线作物与旅程按真实时间继续；模型 Key 需另外配置。")
	label("发布版保留短途日常，最远旅行约7–10天；开发版可加速。导入不会改变已经开始的旅程和作物时间。")

func can_switch() -> bool:
	if host.ai_client.busy or host.home_interactions.book_loading:
		feedback.text = "请等当前 AI 请求结束，再切换或导入存档。"; return false
	if not host.world.persist(): feedback.text = host.world.warning; return false
	return true

func change_save(operation: String) -> void:
	if not can_switch(): return
	var next = null
	if operation == "copy": next = host.save_library.create(slot_name.text, host.world.data)
	elif operation == "new": next = host.save_library.create(slot_name.text)
	elif operation == "load":
		if save_list.get_selected_items().is_empty(): feedback.text = "先选中一个存档。"; return
		next = host.save_library.load_slot(slot_ids[save_list.get_selected_items()[0]])
	if next == null: feedback.text = host.save_library.error; return
	host.activate_save(next)
	saves_page()
	feedback.text = "已切换，后续操作自动保存在这份存档。"

func choose_file(exporting: bool) -> void:
	if not can_switch(): return
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.title = "导出便携存档" if exporting else "导入便携存档"
	if exporting: file_dialog.current_file = "moss-save-" + str(int(Time.get_unix_time_from_system())) + ".json"
	file_dialog.popup_centered(Vector2i(900, 600))

func file_selected(path: String) -> void:
	if not can_switch(): return
	if file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		feedback.text = "已导出，可复制到另一台电脑。" if host.save_library.export_save(host.world, path) else host.save_library.error
	else:
		var next = host.save_library.import_save(path, slot_name.text if is_instance_valid(slot_name) else "导入的小屋")
		if next == null: feedback.text = host.save_library.error; return
		host.activate_save(next)
		saves_page()
		feedback.text = "已导入为新档，源文件保持不变。"
