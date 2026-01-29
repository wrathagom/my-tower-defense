class_name PathState
extends RefCounted

const GridState = preload("res://scripts/state/GridState.gd")

signal path_changed()

var cells: Array[Vector2i] = []
var ordered_cells: Array[Vector2i] = []
var valid: bool = false
var base_start_cell: Vector2i = Vector2i(-1, -1)
var base_end_cell: Vector2i = Vector2i(-1, -1)

func is_path_cell(cell: Vector2i) -> bool:
	return cells.has(cell)

func get_path_points(grid: GridState) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for cell in ordered_cells:
		points.append(grid.cell_to_world(cell))
	return points

func get_path_points_reversed(grid: GridState) -> Array[Vector2]:
	var points := get_path_points(grid)
	points.reverse()
	return points

func clear() -> void:
	cells.clear()
	ordered_cells.clear()
	valid = false
	base_start_cell = Vector2i(-1, -1)
	base_end_cell = Vector2i(-1, -1)

func set_cells(new_cells: Array[Vector2i]) -> void:
	cells = new_cells
	path_changed.emit()

func add_cell(cell: Vector2i) -> void:
	if not cells.has(cell):
		cells.append(cell)
		path_changed.emit()

func remove_cell(cell: Vector2i) -> void:
	if cells.has(cell):
		cells.erase(cell)
		path_changed.emit()
