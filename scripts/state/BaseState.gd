class_name BaseState
extends RefCounted

const PathState = preload("res://scripts/state/PathState.gd")
const GridState = preload("res://scripts/state/GridState.gd")

signal base_created(is_player: bool, base: Node2D)
signal base_destroyed(is_player: bool)

var start: Node2D = null  # Enemy base
var end: Node2D = null    # Player base

func is_base_cell(cell: Vector2i, path: PathState, grid: GridState) -> bool:
	for base_center in [path.base_start_cell, path.base_end_cell]:
		if base_center == Vector2i(-1, -1):
			continue
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var check_cell := Vector2i(base_center.x + dx, base_center.y + dy)
				if cell == check_cell and grid.is_in_bounds(check_cell):
					return true
	return false

func get_base_cells(path: PathState, grid: GridState) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if path.base_start_cell == Vector2i(-1, -1) or path.base_end_cell == Vector2i(-1, -1):
		return cells
	for base_center in [path.base_start_cell, path.base_end_cell]:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var cell := Vector2i(base_center.x + dx, base_center.y + dy)
				if grid.is_in_bounds(cell):
					cells.append(cell)
	return cells

func reset_hp() -> void:
	if start != null and is_instance_valid(start) and start.has_method("reset_hp"):
		start.reset_hp()
	if end != null and is_instance_valid(end) and end.has_method("reset_hp"):
		end.reset_hp()

func clear() -> void:
	if start != null and is_instance_valid(start):
		start.queue_free()
	start = null
	if end != null and is_instance_valid(end):
		end.queue_free()
	end = null
