class_name GridState
extends RefCounted

const GameConfig = preload("res://scripts/GameConfig.gd")

var config: GameConfig
var grid_width: int
var grid_height: int
var cell_size: int
var player_zone_width: int
var path_margin: int

func _init(cfg: GameConfig) -> void:
	config = cfg
	grid_width = cfg.grid_width
	grid_height = cfg.grid_height
	cell_size = cfg.cell_size
	player_zone_width = cfg.player_zone_width
	path_margin = cfg.path_margin

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_width and cell.y < grid_height

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)

func world_to_cell(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))

func is_in_player_zone(cell: Vector2i) -> bool:
	return cell.x >= max(grid_width - player_zone_width, 0)

func is_in_enemy_zone(cell: Vector2i) -> bool:
	return cell.x < min(player_zone_width, grid_width)

func stone_band_bounds() -> Vector2i:
	var start_x: int = max(grid_width - player_zone_width - 10, 0)
	var end_x: int = max(grid_width - player_zone_width - 1, 0)
	if end_x < start_x:
		end_x = start_x
	return Vector2i(start_x, end_x)

func is_in_stone_band(cell: Vector2i) -> bool:
	var band: Vector2i = stone_band_bounds()
	return cell.x >= band.x and cell.x <= band.y

func is_in_iron_band(cell: Vector2i) -> bool:
	return cell.x >= max(grid_width - 13, 0)

func base_band_bounds() -> Vector2i:
	var min_y: int = int(floor(grid_height / 3.0))
	var max_y: int = int(floor(2.0 * grid_height / 3.0)) - 1
	if max_y < min_y:
		min_y = 0
		max_y = grid_height - 1
	return Vector2i(min_y, max_y)

func is_in_base_band(cell: Vector2i) -> bool:
	var band := base_band_bounds()
	return cell.y >= band.x and cell.y <= band.y

func get_player_zone_start_x() -> int:
	return max(grid_width - player_zone_width, 0)
