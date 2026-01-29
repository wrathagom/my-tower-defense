class_name OccupancyState
extends RefCounted

signal building_placed(cell: Vector2i, building: Node2D)
signal building_removed(cell: Vector2i)
signal enemy_tower_placed(cell: Vector2i, tower: Node2D)
signal enemy_tower_removed(cell: Vector2i)

var occupied: Dictionary = {}
var building_by_cell: Dictionary = {}
var enemy_towers: Array[Node2D] = []
var enemy_tower_by_cell: Dictionary = {}

func is_occupied(cell: Vector2i) -> bool:
	return occupied.has(cell) or building_by_cell.has(cell) or enemy_tower_by_cell.has(cell)

func is_building_cell(cell: Vector2i) -> bool:
	return building_by_cell.has(cell)

func is_enemy_tower_cell(cell: Vector2i) -> bool:
	return enemy_tower_by_cell.has(cell)

func get_building_at(cell: Vector2i) -> Node2D:
	return building_by_cell.get(cell, null) as Node2D

func get_enemy_tower_at(cell: Vector2i) -> Node2D:
	return enemy_tower_by_cell.get(cell, null) as Node2D

func register_occupied(cell: Vector2i) -> void:
	occupied[cell] = true

func unregister_occupied(cell: Vector2i) -> void:
	occupied.erase(cell)

func register_building(cell: Vector2i, building: Node2D) -> void:
	building_by_cell[cell] = building
	building_placed.emit(cell, building)

func unregister_building(cell: Vector2i) -> void:
	if building_by_cell.has(cell):
		building_by_cell.erase(cell)
		building_removed.emit(cell)

func register_enemy_tower(cell: Vector2i, tower: Node2D) -> void:
	enemy_towers.append(tower)
	enemy_tower_by_cell[cell] = tower
	enemy_tower_placed.emit(cell, tower)

func unregister_enemy_tower(cell: Vector2i) -> bool:
	if not enemy_tower_by_cell.has(cell):
		return false
	var tower: Node2D = enemy_tower_by_cell[cell] as Node2D
	enemy_tower_by_cell.erase(cell)
	if tower != null:
		enemy_towers.erase(tower)
	enemy_tower_removed.emit(cell)
	return true

func clear_all() -> void:
	occupied.clear()
	building_by_cell.clear()
	enemy_towers.clear()
	enemy_tower_by_cell.clear()

func clear_buildings() -> void:
	building_by_cell.clear()
	occupied.clear()

func clear_enemy_towers() -> void:
	enemy_towers.clear()
	enemy_tower_by_cell.clear()

func get_all_buildings() -> Array:
	var unique: Dictionary = {}
	for building in building_by_cell.values():
		if building != null and is_instance_valid(building):
			unique[building] = true
	return unique.keys()
