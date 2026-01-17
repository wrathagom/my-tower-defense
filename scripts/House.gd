extends Node2D

@export var cell: Vector2i
@export var cell_size := 64

func _ready() -> void:
	position = Vector2(cell.x * cell_size, cell.y * cell_size)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(cell_size * 2, cell_size * 2))
	draw_rect(rect, Color(0.7, 0.7, 0.8), true)
	draw_rect(rect, Color(0.3, 0.3, 0.4), false, 2.0)
