extends Node2D
const Art = preload("res://scripts/item_art.gd")
var state: Dictionary = {}
var rug: Sprite2D
var current = ""

func _ready() -> void:
	rug = Sprite2D.new()
	rug.position = Vector2(426, 548)
	rug.scale = Vector2(0.76, 0.72)
	rug.rotation = 0.13
	rug.material = Art.matte_material()
	add_child(rug)

func _process(_delta: float) -> void:
	if state.is_empty() or current == state.rug: return
	current = state.rug
	rug.texture = Art.rug(current)
	var factor = 360.0 / rug.texture.get_width()
	rug.scale = Vector2(factor, factor * 0.91)
