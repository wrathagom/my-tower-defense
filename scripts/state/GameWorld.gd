class_name GameWorld
extends RefCounted

const GameConfig = preload("res://scripts/GameConfig.gd")
const GridState = preload("res://scripts/state/GridState.gd")
const PathState = preload("res://scripts/state/PathState.gd")
const OccupancyState = preload("res://scripts/state/OccupancyState.gd")
const ResourceState = preload("res://scripts/state/ResourceState.gd")
const FogState = preload("res://scripts/state/FogState.gd")
const BaseState = preload("res://scripts/state/BaseState.gd")

var config: GameConfig
var grid: GridState
var path: PathState
var occupancy: OccupancyState
var resources: ResourceState
var fog: FogState
var bases: BaseState

func _init(cfg: GameConfig) -> void:
	config = cfg
	grid = GridState.new(cfg)
	path = PathState.new()
	occupancy = OccupancyState.new()
	resources = ResourceState.new()
	fog = FogState.new()
	bases = BaseState.new()

func reset_for_new_game() -> void:
	path.cells.clear()
	path.ordered_cells.clear()
	path.valid = false
	occupancy.clear_all()
	fog.reset(grid)
	bases.reset_hp()

func is_cell_blocked(cell: Vector2i) -> bool:
	if not grid.is_in_bounds(cell):
		return true
	if path.is_path_cell(cell):
		return true
	if occupancy.is_occupied(cell):
		return true
	if resources.has_any_at(cell):
		return true
	if bases.is_base_cell(cell, path, grid):
		return true
	return false

func is_buildable(cell: Vector2i) -> bool:
	if not grid.is_in_bounds(cell):
		return false
	if path.is_path_cell(cell):
		return false
	if occupancy.is_occupied(cell):
		return false
	if resources.has_any_at(cell):
		return false
	if bases.is_base_cell(cell, path, grid):
		return false
	return true
