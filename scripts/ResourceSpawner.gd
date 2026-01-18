extends Node
class_name ResourceSpawner

var main: Node
var rng: RandomNumberGenerator
var resource_defs: Dictionary = {}
var resource_order: Array[String] = []

func setup(main_node: Node, defs: Dictionary, order: Array[String] = []) -> void:
	main = main_node
	resource_defs = defs
	resource_order.clear()
	for resource_id in order:
		resource_order.append(resource_id)
	rng = RandomNumberGenerator.new()

func spawn_resources() -> void:
	clear_resources()
	for resource_id in _resolved_order():
		_spawn_resource(resource_id)

func spawn_from_cells(resource_cells: Dictionary) -> void:
	clear_resources()
	for resource_id in _resolved_order():
		var cells: Array = resource_cells.get(resource_id, [])
		for cell in cells:
			if cell is Vector2i:
				_place_resource(resource_id, cell)

func clear_resources() -> void:
	for resource_id in _resolved_order():
		_clear_resource(resource_id)

func place_resource(resource_id: String, top_left: Vector2i) -> bool:
	return _place_resource(resource_id, top_left)

func remove_resource_at(cell: Vector2i) -> bool:
	for resource_id in _resolved_order():
		var map: Dictionary = main._resource_map(resource_id)
		if not map.has(cell):
			continue
		var node: Node2D = map[cell] as Node2D
		return _remove_resource(resource_id, node)
	return false

func _resolved_order() -> Array[String]:
	if not resource_order.is_empty():
		return resource_order
	var order: Array[String] = []
	for resource_id in resource_defs.keys():
		order.append(resource_id)
	return order

func _spawn_resource(resource_id: String) -> void:
	var def: Dictionary = resource_defs.get(resource_id, {})
	if def.is_empty():
		return
	var count: int = int(def.get("count", 0))
	var size: int = int(def.get("size", 2))
	if count <= 0:
		return
	if main.config.grid_width < size or main.config.grid_height < size:
		return
	_seed_rng(resource_id)
	var ensure_zone: String = str(def.get("ensure_zone", ""))
	var ensured: bool = ensure_zone == ""
	var attempts: int = 0
	var placed: int = 0
	var max_attempts: int = count * 20
	while placed < count and attempts < max_attempts:
		var require_zone: bool = ensure_zone != "" and not ensured
		var cell: Vector2i = _pick_cell(def, require_zone)
		attempts += 1
		if cell == Vector2i(-1, -1):
			continue
		if _place_resource(resource_id, cell):
			placed += 1
			if require_zone and _cell_in_zone(cell, ensure_zone):
				ensured = true
	if ensure_zone != "" and not ensured:
		_ensure_resource_in_zone(resource_id, def)

func _clear_resource(resource_id: String) -> void:
	var nodes: Array = main._resource_nodes(resource_id)
	for node in nodes:
		if node != null and is_instance_valid(node):
			node.queue_free()
	nodes.clear()
	var map: Dictionary = main._resource_map(resource_id)
	map.clear()

func _remove_resource(resource_id: String, node: Node2D) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	var def: Dictionary = resource_defs.get(resource_id, {})
	var size: int = int(def.get("size", 2))
	var top_left: Vector2i = node.get("cell")
	var map: Dictionary = main._resource_map(resource_id)
	for x in range(size):
		for y in range(size):
			var cell := top_left + Vector2i(x, y)
			map.erase(cell)
	var nodes: Array = main._resource_nodes(resource_id)
	nodes.erase(node)
	node.queue_free()
	return true

func _pick_cell(def: Dictionary, require_zone: bool) -> Vector2i:
	var size: int = int(def.get("size", 2))
	var min_x: int = 0
	var max_x: int = main.config.grid_width - size
	var min_y: int = 0
	var max_y: int = main.config.grid_height - size
	if require_zone:
		var zone: String = str(def.get("ensure_zone", ""))
		if zone == "player_zone":
			min_x = max(main.config.grid_width - main.config.player_zone_width, 0)
			max_x = max(main.config.grid_width - size, 0)
		elif zone == "stone_band":
			var band: Vector2i = main._stone_band_bounds()
			min_x = band.x
			max_x = band.y
	if max_x < min_x or max_y < min_y:
		return Vector2i(-1, -1)
	var x: int = rng.randi_range(min_x, max_x)
	var y: int = rng.randi_range(min_y, max_y)
	return Vector2i(x, y)

func _place_resource(resource_id: String, top_left: Vector2i) -> bool:
	var def: Dictionary = resource_defs.get(resource_id, {})
	if def.is_empty():
		return false
	var size: int = int(def.get("size", 2))
	if not _can_place_resource(top_left, size):
		return false
	var scene_path: String = str(def.get("scene", ""))
	if scene_path == "":
		return false
	var node: Node2D = load(scene_path).instantiate() as Node2D
	node.set("cell", top_left)
	node.set("cell_size", main.config.cell_size)
	main.add_child(node)
	var nodes: Array = main._resource_nodes(resource_id)
	nodes.append(node)
	var map: Dictionary = main._resource_map(resource_id)
	for x in range(size):
		for y in range(size):
			var cell := top_left + Vector2i(x, y)
			map[cell] = node
	return true

func _can_place_resource(top_left: Vector2i, size: int) -> bool:
	for x in range(size):
		for y in range(size):
			var cell := top_left + Vector2i(x, y)
			if not main._is_in_bounds(cell):
				return false
			if main._is_base_cell(cell):
				return false
			if main._is_path_cell(cell):
				return false
			if main._enemy_tower_by_cell.has(cell):
				return false
			if main._resource_cell_has_any(cell):
				return false
	return true

func _ensure_resource_in_zone(resource_id: String, def: Dictionary) -> void:
	var size: int = int(def.get("size", 2))
	var zone: String = str(def.get("ensure_zone", ""))
	var bounds: Vector2i = _zone_bounds(zone, size)
	var min_x: int = bounds.x
	var max_x: int = bounds.y
	if max_x < min_x:
		return
	var max_y: int = main.config.grid_height - size
	for y in range(max_y + 1):
		for x in range(min_x, max_x + 1):
			if _place_resource(resource_id, Vector2i(x, y)):
				return

func _zone_bounds(zone: String, size: int) -> Vector2i:
	var min_x: int = 0
	var max_x: int = main.config.grid_width - size
	if zone == "player_zone":
		min_x = max(main.config.grid_width - main.config.player_zone_width, 0)
		max_x = max(main.config.grid_width - size, 0)
	elif zone == "stone_band":
		var band: Vector2i = main._stone_band_bounds()
		min_x = band.x
		max_x = band.y
	return Vector2i(min_x, max_x)

func _cell_in_zone(cell: Vector2i, zone: String) -> bool:
	if zone == "player_zone":
		return main._is_in_player_zone(cell)
	if zone == "stone_band":
		return main._is_in_stone_band(cell)
	return true

func _seed_rng(resource_id: String) -> void:
	if main.config.random_seed == 0:
		rng.randomize()
	else:
		var offset: int = abs(resource_id.hash()) % 997
		rng.seed = main.config.random_seed + offset
