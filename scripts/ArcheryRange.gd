extends Node2D

@export var cell: Vector2i
@export var cell_size := 64
@export var level := 1
var upgrade_in_progress := false
var _show_upgrade_indicator := false
var _can_upgrade := false

func _ready() -> void:
	position = Vector2(cell.x * cell_size, cell.y * cell_size)
	queue_redraw()

func set_upgrade_indicator(show: bool, can_upgrade: bool, _cost_text: String = "") -> void:
	_show_upgrade_indicator = show
	_can_upgrade = can_upgrade
	queue_redraw()

func upgrade() -> void:
	level += 1
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(cell_size * 3, cell_size * 3))
	var body_color := Color(0.75, 0.5, 0.3) if level == 1 else Color(0.9, 0.7, 0.45)
	draw_rect(rect, body_color, true)
	draw_rect(rect, Color(0.35, 0.2, 0.1), false, 2.0)
	if _show_upgrade_indicator:
		_draw_upgrade_indicator()

func _draw_upgrade_indicator() -> void:
	var size := cell_size * 0.8
	var center := Vector2(cell_size * 1.5, cell_size * 1.5)
	var color := Color(0.2, 0.9, 0.3, 0.9) if _can_upgrade else Color(0.5, 0.5, 0.5, 0.6)
	var points := PackedVector2Array([
		center + Vector2(0, -size * 0.4),
		center + Vector2(-size * 0.35, size * 0.3),
		center + Vector2(size * 0.35, size * 0.3),
	])
	draw_polygon(points, PackedColorArray([color, color, color]))
