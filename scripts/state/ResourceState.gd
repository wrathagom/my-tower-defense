class_name ResourceState
extends RefCounted

const GridState = preload("res://scripts/state/GridState.gd")

signal resource_added(resource_id: String, cell: Vector2i)
signal resource_removed(resource_id: String, cell: Vector2i)

var state: Dictionary = {}  # resource_id -> {nodes: [], by_cell: {}}
var defs: Dictionary = {}
var order: Array[String] = []

func initialize(resource_defs: Dictionary, resource_order: Array[String]) -> void:
	defs = resource_defs
	order = resource_order
	state.clear()
	for resource_id in order:
		if not defs.has(resource_id):
			continue
		state[resource_id] = {
			"nodes": [],
			"by_cell": {},
		}

func nodes(resource_id: String) -> Array:
	var s: Dictionary = state.get(resource_id, {})
	return s.get("nodes", [])

func by_cell(resource_id: String) -> Dictionary:
	var s: Dictionary = state.get(resource_id, {})
	return s.get("by_cell", {})

func has_any_at(cell: Vector2i) -> bool:
	for resource_id in defs.keys():
		if by_cell(resource_id).has(cell):
			return true
	return false

func get_node_at(resource_id: String, cell: Vector2i) -> Node2D:
	return by_cell(resource_id).get(cell, null) as Node2D

func register_node(resource_id: String, cell: Vector2i, node: Node2D) -> void:
	if not state.has(resource_id):
		state[resource_id] = {"nodes": [], "by_cell": {}}
	state[resource_id]["nodes"].append(node)
	state[resource_id]["by_cell"][cell] = node
	resource_added.emit(resource_id, cell)

func unregister_node(resource_id: String, cell: Vector2i) -> void:
	if not state.has(resource_id):
		return
	var node: Node2D = state[resource_id]["by_cell"].get(cell, null) as Node2D
	if node != null:
		state[resource_id]["nodes"].erase(node)
	state[resource_id]["by_cell"].erase(cell)
	resource_removed.emit(resource_id, cell)

func clear_all() -> void:
	for resource_id in state.keys():
		state[resource_id]["nodes"].clear()
		state[resource_id]["by_cell"].clear()

func collect_cells(resource_id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen: Dictionary = {}
	for node in nodes(resource_id):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get"):
			continue
		var cell_value = node.get("cell")
		if typeof(cell_value) != TYPE_VECTOR2I:
			continue
		var cell: Vector2i = cell_value
		if seen.has(cell):
			continue
		seen[cell] = true
		cells.append(cell)
	return cells

func has_resource_in_zone(resource_id: String, zone: String, grid: GridState) -> bool:
	var def: Dictionary = defs.get(resource_id, {})
	var rightmost: int = int(def.get("validation_rightmost", 0))
	for node in nodes(resource_id):
		if node == null or not is_instance_valid(node):
			continue
		var cell_value = node.get("cell")
		if typeof(cell_value) != TYPE_VECTOR2I:
			continue
		var cell: Vector2i = cell_value
		if zone == "player_zone":
			if grid.is_in_player_zone(cell):
				return true
		elif zone == "rightmost":
			if rightmost > 0 and cell.x >= max(grid.grid_width - rightmost, 0):
				return true
	return false
