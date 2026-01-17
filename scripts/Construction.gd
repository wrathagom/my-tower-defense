extends Node2D
class_name Construction

@export var cell_size := 64
@export var size_cells := 1
@export var duration := 10.0

var _progress := 0.0

signal completed

func _ready() -> void:
	add_to_group("construction")

func _process(delta: float) -> void:
	if duration <= 0.0:
		_finish()
		return
	_progress = minf(1.0, _progress + delta / duration)
	queue_redraw()
	if _progress >= 1.0:
		_finish()

func _finish() -> void:
	completed.emit()
	queue_free()

func _draw() -> void:
	var width := cell_size * size_cells
	var rect := Rect2(0, 0, width, width)
	var base_color := Color(0.8, 0.7, 0.2, 0.35)
	var border_color := Color(0.8, 0.7, 0.2, 0.7)
	draw_rect(rect, base_color, true)
	draw_rect(rect, border_color, false, 2.0)
	var bar_height := 6.0
	var bar_rect := Rect2(4.0, width - bar_height - 4.0, width - 8.0, bar_height)
	draw_rect(bar_rect, Color(0.1, 0.1, 0.1, 0.6), true)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * _progress, bar_rect.size.y)), Color(0.2, 0.9, 0.3, 0.9), true)
