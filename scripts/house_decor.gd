extends Node2D
var state: Dictionary = {}

func _draw() -> void:
	if state.is_empty(): return
	var color = {"spring": Color("da9da4"), "summer": Color("70aa94"), "autumn": Color("d9a35f"), "winter": Color("b8d9dc")}[state.theme]
	# Small seasonal leaves on the floor; keep the painted window unobstructed.
	for i in range(7):
		var center = Vector2(645 + i * 9, 565 + sin(i * 2.1) * 17)
		draw_colored_polygon(PackedVector2Array([center, center + Vector2(5, -3), center + Vector2(10, 1), center + Vector2(4, 3)]), Color(color, 0.48))
	if "lantern" in state.equipped:
		draw_line(Vector2(622, 222), Vector2(622, 276), Color("856546"), 3, true)
		draw_circle(Vector2(622, 301), 40, Color(1, 0.8, 0.36, 0.16))
		draw_style_box(lamp_box(), Rect2(604, 279, 36, 45))
		draw_line(Vector2(608, 279), Vector2(636, 279), Color("816846"), 5, true)
	if "bunting" in state.equipped:
		for i in range(7):
			var a = Vector2(399 + i * 32, 231 + sin(i * PI / 6.0) * 21)
			draw_line(a, a + Vector2(32, 0), Color("8b7354"), 2, true)
			draw_colored_polygon(PackedVector2Array([a, a + Vector2(25, 0), a + Vector2(12, 28)]), color if i % 2 == 0 else Color("94aa7c"))
	# Modest fixed-size keepsakes, painted in muted colors with small contact shadows.
	if "tiecloth" in state.equipped:
		draw_colored_polygon(PackedVector2Array([Vector2(345, 327), Vector2(435, 337), Vector2(435, 354), Vector2(345, 343)]), Color("637e99"))
		for i in range(8):
			var p = Vector2(351 + i * 11, 333 + i * 1.2)
			draw_arc(p, 3, 0, TAU, 12, Color("d7ddd6"), 1, true)
			draw_line(p + Vector2(0, 9), p + Vector2(-1, 15), Color("c7d2cf"), 1, true)
	if "pariscup" in state.equipped:
		paint_small_ellipse(Vector2(356, 307), Vector2(15, 5), Color(0.28, 0.24, 0.17, 0.18))
		paint_small_ellipse(Vector2(356, 305), Vector2(13, 4), Color("c9c4ad"))
		draw_arc(Vector2(368, 295), 6, -PI / 2, PI / 2, 14, Color("ded4b7"), 3, true)
		draw_colored_polygon(PackedVector2Array([Vector2(346, 288), Vector2(366, 288), Vector2(363, 303), Vector2(350, 303)]), Color("e1d8be"))
		paint_small_ellipse(Vector2(356, 288), Vector2(10, 3), Color("806952"))
		draw_circle(Vector2(357, 296), 2, Color("ba8890"))
	if "stonelamp" in state.equipped:
		draw_circle(Vector2(675, 424), 29, Color(0.98, 0.84, 0.50, 0.12))
		paint_small_ellipse(Vector2(675, 438), Vector2(18, 5), Color(0.25, 0.25, 0.21, 0.24))
		draw_colored_polygon(PackedVector2Array([Vector2(659, 437), Vector2(661, 420), Vector2(674, 412), Vector2(687, 422), Vector2(690, 437)]), Color("777d72"))
		for i in range(5): draw_circle(Vector2(665 + i * 4, 424 + sin(i * 2.0) * 7), 1.8, Color("edcf87"))

func paint_small_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points = PackedVector2Array()
	for i in range(24): points.append(center + Vector2(cos(i * TAU / 24), sin(i * TAU / 24)) * radius)
	draw_colored_polygon(points, color)

func lamp_box() -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = Color("f4cb76")
	box.set_corner_radius_all(10)
	return box
