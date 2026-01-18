extends Node2D

@export var cell: Vector2i
@export var cell_size := 64
var has_cutter := false

func _ready() -> void:
	position = Vector2(cell.x * cell_size, cell.y * cell_size)
	queue_redraw()

func _draw() -> void:
	var color := Color(0.35, 0.32, 0.28)
	var radius := cell_size * 0.45
	var centers := [
		Vector2(cell_size * 0.5, cell_size * 0.5),
		Vector2(cell_size * 1.5, cell_size * 0.5),
		Vector2(cell_size * 0.5, cell_size * 1.5),
		Vector2(cell_size * 1.5, cell_size * 1.5),
	]
	for center in centers:
		draw_circle(center, radius, color)
