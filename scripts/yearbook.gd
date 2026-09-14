extends RefCounted
static var entries: Dictionary = {}
static func entry(day: String) -> Dictionary:
	if entries.is_empty():
		var file = FileAccess.open("res://assets/text/yearbook.json", FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary: entries = parsed.get("entries", {})
	var id = day.substr(5, 5)
	return entries.get(id, {"title":"窗边的一页", "pages":["今天先坐在窗边，看风慢慢经过。", "给自己留一点休息的时间。", "明天再来翻一页吧。"]}).duplicate(true)
