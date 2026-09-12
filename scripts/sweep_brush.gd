extends Node2D
## Native strokes: no cutout texture or matte edge.
func _draw() -> void:
	draw_line(Vector2(40, -65), Vector2(0, 0), Color("806247"), 5, true)
	for i in range(12):
		draw_line(Vector2(-8 + i, -5), Vector2(-27 + i * 3, 24), Color("b9a56e"), 3, true)
	draw_line(Vector2(-10, 1), Vector2(8, 7), Color("857548"), 4, true)
	for i in range(4):
		draw_arc(Vector2(-45 - i * 13, 25), 7 + i * 2, 0.3, 1.9, 10, Color(0.8, 0.78, 0.59, 0.45), 2, true)
