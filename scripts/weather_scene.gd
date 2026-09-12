extends Node2D
var state: Dictionary = {}
var time = 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	if state.is_empty(): return
	var kind = state.weather.kind
	if kind != "sunny":
		draw_rect(Rect2(24, 128, 1010, 590), Color(0.25, 0.32, 0.4, 0.14 if kind == "rainy" else 0.08))
	else:
		var glow = 0.025 + sin(time * 0.4) * 0.01
		draw_rect(Rect2(164, 173, 145, 140), Color(1, 0.85, 0.4, glow))
	if kind == "rainy":
		# Rain is limited to the garden and visible window, never the room floor/UI.
		for i in range(44):
			var x = 756 + fmod(i * 67.0 + time * 16, 261)
			var y = 199 + fmod(i * 83.0 + time * 180, 480)
			draw_line(Vector2(x, y), Vector2(x - 5, y + 17), Color(0.83, 0.91, 0.94, 0.48), 1.5, true)
		for i in range(12):
			var x = 175 + fmod(i * 29.0, 115)
			var y = 199 + fmod(i * 21.0 + time * 75, 83)
			draw_line(Vector2(x, y), Vector2(x - 2, y + 10), Color(0.83, 0.91, 0.94, 0.3), 1, true)
	var leaves = maxi(0, (100 - int(state.cleanliness)) / 10)
	for i in range(leaves):
		var pos = Vector2(521 + (i % 3) * 30, 594 + (i / 3) * 21)
		draw_colored_polygon(PackedVector2Array([pos, pos + Vector2(9, -3), pos + Vector2(15, 4), pos + Vector2(7, 6)]), Color("b89459"))
