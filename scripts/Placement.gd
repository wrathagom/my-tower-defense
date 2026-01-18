extends Node

var main: Node
var economy: Node

var hover_cell := Vector2i(-1, -1)
var hover_resource_top_left := Vector2i(-1, -1)
var hover_resource_valid := false
var hover_resource_size := 2
var hover_build_top_left := Vector2i(-1, -1)
var hover_build_valid := false
var hover_build_size := 1

func setup(main_node: Node, economy_node: Node) -> void:
	main = main_node
	economy = economy_node

func handle_build_click(world_pos: Vector2, mode: String) -> bool:
	var def: Dictionary = main._building_defs.get(mode, {})
	if def.is_empty():
		return false
	var placement: String = str(def.get("placement", "grid"))
	if _is_resource_placement(placement):
		return _try_build_resource(def, world_pos)
	return _try_build_grid(def, world_pos)

func update_hover(world_pos: Vector2, mode: String) -> void:
	var cell := Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not main._is_in_bounds(cell):
		if hover_cell != Vector2i(-1, -1):
			hover_cell = Vector2i(-1, -1)
			hover_resource_top_left = Vector2i(-1, -1)
			hover_resource_valid = false
			hover_build_top_left = Vector2i(-1, -1)
			hover_build_valid = false
			main.queue_redraw()
		return
	hover_cell = cell
	var def: Dictionary = main._building_defs.get(mode, {})
	if def.is_empty():
		hover_resource_top_left = Vector2i(-1, -1)
		hover_resource_valid = false
		hover_build_top_left = Vector2i(-1, -1)
		hover_build_valid = false
		main.queue_redraw()
		return
	var placement: String = str(def.get("placement", "grid"))
	if _is_resource_placement(placement):
		_update_resource_hover(cell, def)
		return
	_update_grid_hover(cell, def)
	main.queue_redraw()

func draw_hover(drawer: Node2D, mode: String) -> void:
	if hover_cell == Vector2i(-1, -1):
		return
	if hover_resource_top_left != Vector2i(-1, -1):
		_draw_resource_hover(drawer)
		return
	if hover_build_top_left != Vector2i(-1, -1):
		_draw_building_hover(drawer)

func _update_resource_hover(cell: Vector2i, def: Dictionary) -> void:
	hover_build_top_left = Vector2i(-1, -1)
	hover_build_valid = false
	var placement: String = str(def.get("placement", ""))
	var resource_map: Dictionary = main._resource_map(placement)
	if not resource_map.has(cell):
		hover_resource_top_left = Vector2i(-1, -1)
		hover_resource_valid = false
		main.queue_redraw()
		return
	var resource: Node2D = resource_map[cell] as Node2D
	var top_left: Vector2i = resource.get("cell")
	hover_resource_top_left = top_left
	hover_resource_size = int(def.get("size", 2))
	var has_cutter: bool = resource.get("has_cutter") != null and resource.get("has_cutter") != false
	var meets_reqs := _requirements_met(def)
	var zone_ok := _resource_zone_ok(cell, placement)
	hover_resource_valid = zone_ok and meets_reqs and not has_cutter and economy.can_afford_cost(def)
	main.queue_redraw()

func _draw_resource_hover(drawer: Node2D) -> void:
	if hover_resource_top_left == Vector2i(-1, -1):
		return
	var color := Color(0.2, 0.8, 0.3, 0.4) if hover_resource_valid else Color(0.9, 0.2, 0.2, 0.4)
	for x in range(hover_resource_size):
		for y in range(hover_resource_size):
			var cell := hover_resource_top_left + Vector2i(x, y)
			var rect := Rect2(cell.x * main.cell_size, cell.y * main.cell_size, main.cell_size, main.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _update_grid_hover(cell: Vector2i, def: Dictionary) -> void:
	hover_resource_top_left = Vector2i(-1, -1)
	hover_resource_valid = false
	hover_build_top_left = cell
	hover_build_size = int(def.get("size", 1))
	var has_resources: bool = economy.can_afford_cost(def)
	var meets_reqs := _requirements_met(def)
	hover_build_valid = _can_place_structure(cell, hover_build_size) and has_resources and meets_reqs
	main.queue_redraw()

func _draw_building_hover(drawer: Node2D) -> void:
	if hover_build_top_left == Vector2i(-1, -1):
		return
	var color := Color(0.2, 0.8, 0.3, 0.4) if hover_build_valid else Color(0.9, 0.2, 0.2, 0.4)
	for x in range(hover_build_size):
		for y in range(hover_build_size):
			var cell := hover_build_top_left + Vector2i(x, y)
			var rect := Rect2(cell.x * main.cell_size, cell.y * main.cell_size, main.cell_size, main.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _try_build_grid(def: Dictionary, world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	var size: int = int(def.get("size", 1))
	if not _can_place_structure(cell, size):
		return false
	if not _requirements_met(def):
		return false
	if not economy.can_afford_cost(def):
		return false
	if not economy.spend_cost(def):
		return false
	var build_time: float = float(def.get("build_time", 0.0))
	var construction: Node2D = _start_construction(cell, size, build_time)
	construction.completed.connect(Callable(self, "_finish_grid_building").bind(construction, def, cell, size))
	for x in range(size):
		for y in range(size):
			var grid_cell := cell + Vector2i(x, y)
			main._building_by_cell[grid_cell] = construction
	if def.get("uses_occupied", false):
		main._occupied[cell] = construction
	return true

func _try_build_resource(def: Dictionary, world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	var placement: String = str(def.get("placement", ""))
	var resource_map: Dictionary = main._resource_map(placement)
	if not resource_map.has(cell):
		return false
	if not _resource_zone_ok(cell, placement):
		return false
	if not _requirements_met(def):
		return false
	var resource: Node2D = resource_map[cell] as Node2D
	if resource.get("has_cutter"):
		return false
	if not economy.can_afford_cost(def):
		return false
	if not economy.spend_cost(def):
		return false
	resource.set("has_cutter", "building")
	var top_left: Vector2i = resource.get("cell")
	var size: int = int(def.get("size", 2))
	var build_time: float = float(def.get("build_time", 0.0))
	var construction: Node2D = _start_construction(top_left, size, build_time)
	construction.completed.connect(Callable(self, "_finish_resource_building").bind(construction, def, resource))
	return true

func _finish_grid_building(construction: Node2D, def: Dictionary, top_left: Vector2i, size: int) -> void:
	_clear_construction_cells(top_left, size, construction)
	var spawn_type: String = str(def.get("spawn_type", "scene"))
	var path: String = str(def.get("path", ""))
	var building: Node2D = null
	if spawn_type == "script":
		var script: Script = load(path)
		building = script.new() as Node2D
		building.set("cell", top_left)
		building.set("cell_size", main.cell_size)
		main.add_child(building)
	else:
		building = _place_structure(path, top_left, size)
	_apply_building_effect(def, building)
	if def.get("uses_occupied", false):
		if main._occupied.get(top_left) == construction:
			main._occupied[top_left] = building

func _finish_resource_building(_construction: Node2D, def: Dictionary, resource: Node2D) -> void:
	if resource == null or not is_instance_valid(resource):
		return
	var path: String = str(def.get("path", ""))
	var cutter: Node2D = load(path).instantiate() as Node2D
	cutter.cell_size = main.cell_size
	cutter.position = Vector2(main.cell_size, main.cell_size)
	var kind: String = str(def.get("resource_kind", ""))
	if kind == "wood":
		cutter.wood_produced.connect(_on_wood_produced)
	elif kind == "stone":
		cutter.stone_produced.connect(_on_stone_produced)
	elif kind == "iron":
		cutter.iron_produced.connect(_on_iron_produced)
	resource.add_child(cutter)
	resource.set("has_cutter", true)

func _apply_building_effect(def: Dictionary, building: Node2D) -> void:
	if building == null:
		return
	var effect: String = str(def.get("effect", ""))
	if effect == "house":
		economy.add_unit_capacity(main.house_capacity)
	elif effect == "farm":
		if building.has_signal("food_produced"):
			building.food_produced.connect(_on_food_produced)
	elif effect == "wood_storage":
		economy.add_wood_cap(main.storage_capacity)
	elif effect == "food_storage":
		economy.add_food_cap(main.storage_capacity)
	elif effect == "stone_storage":
		economy.add_stone_cap(main.storage_capacity)
	elif effect == "iron_storage":
		economy.add_iron_cap(main.storage_capacity)
	elif effect == "archery_range":
		main._archery_range_level = max(main._archery_range_level, 1)
		main._register_archery_range(building)
		economy.update_buttons_for_base_level(main._base_level, main._archery_range_level)

func _place_structure(scene_path: String, top_left: Vector2i, size: int) -> Node2D:
	var building: Node2D = load(scene_path).instantiate() as Node2D
	building.set("cell", top_left)
	building.set("cell_size", main.cell_size)
	main.add_child(building)
	for x in range(size):
		for y in range(size):
			var cell := top_left + Vector2i(x, y)
			main._building_by_cell[cell] = building
	return building

func _start_construction(top_left: Vector2i, size: int, duration: float) -> Node2D:
	var ConstructionScript: Script = load("res://scripts/Construction.gd")
	var construction: Node2D = ConstructionScript.new()
	construction.cell_size = main.cell_size
	construction.size_cells = size
	construction.duration = duration
	construction.position = Vector2(top_left.x * main.cell_size, top_left.y * main.cell_size)
	main.add_child(construction)
	return construction

func _finish_tower(construction: Node2D, cell: Vector2i) -> void:
	var tower := preload("res://scripts/Tower.gd").new()
	tower.cell = cell
	tower.cell_size = main.cell_size
	main.add_child(tower)
	if main._occupied.get(cell) == construction:
		main._occupied[cell] = tower

func _clear_construction_cells(top_left: Vector2i, size: int, construction: Node2D) -> void:
	for x in range(size):
		for y in range(size):
			var cell := top_left + Vector2i(x, y)
			if main._building_by_cell.get(cell) == construction:
				main._building_by_cell.erase(cell)

func _can_place_structure(top_left: Vector2i, size: int) -> bool:
	for x in range(size):
		for y in range(size):
			var cell := top_left + Vector2i(x, y)
			if not main._is_in_bounds(cell):
				return false
			if not main._is_in_player_zone(cell):
				return false
			if main._is_path_cell(cell):
				return false
			if main._occupied.has(cell):
				return false
			if main._resource_cell_has_any(cell):
				return false
			if main._enemy_tower_by_cell.has(cell):
				return false
			if main._building_by_cell.has(cell):
				return false
	return true

func _requirements_met(def: Dictionary) -> bool:
	var requirements: Array = def.get("requirements", [])
	if requirements.is_empty():
		var min_level: int = def.get("min_base_level", 1)
		if main._base_level < min_level:
			return false
		var requires_range: bool = def.get("requires_archery_range", false)
		var requires_upgrade: bool = def.get("requires_archery_range_upgrade", false)
		if requires_range and main._archery_range_level < 1:
			return false
		if requires_upgrade and main._archery_range_level < 2:
			return false
		return true
	for req in requirements:
		if req is Dictionary:
			var req_type: String = str(req.get("type", ""))
			if req_type == "base_level":
				if main._base_level < int(req.get("value", 1)):
					return false
			elif req_type == "archery_level":
				if main._archery_range_level < int(req.get("value", 0)):
					return false
	return true

func _on_food_produced(amount: int) -> void:
	economy.add_food(amount)

func _on_wood_produced(amount: int) -> void:
	economy.add_wood(amount)

func _on_stone_produced(amount: int) -> void:
	economy.add_stone(amount)

func _on_iron_produced(amount: int) -> void:
	economy.add_iron(amount)

func _is_resource_placement(placement: String) -> bool:
	return main != null and main._resource_defs.has(placement)
func _resource_zone_ok(cell: Vector2i, placement: String) -> bool:
	return main._is_in_player_zone(cell)
