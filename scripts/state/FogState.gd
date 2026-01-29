class_name FogState
extends RefCounted

const GridState = preload("res://scripts/state/GridState.gd")

signal column_revealed(column: int)

var revealed_column: int = -1
var enabled: bool = true
var color: Color = Color(0.05, 0.05, 0.1, 0.85)

func reset(grid: GridState) -> void:
	revealed_column = grid.grid_width - grid.player_zone_width

func reveal_to(column: int) -> void:
	if column < revealed_column:
		revealed_column = column
		column_revealed.emit(column)

func is_visible(column: int) -> bool:
	return column >= revealed_column

func is_cell_visible(cell: Vector2i) -> bool:
	return cell.x >= revealed_column
