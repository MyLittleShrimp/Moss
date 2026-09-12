extends Node
var enabled = true
var busy = false
var status_text = "模拟延迟，只用于测试"

func reply(_text: String, _facts: Dictionary) -> Dictionary:
	busy = true
	await get_tree().create_timer(0.1).timeout
	busy = false
	return {"ok": true, "text": "SHOULD_NOT_APPEAR_STALE_REPLY"}
