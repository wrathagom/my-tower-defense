extends Node

var main: Node
var economy: Node

var hover_cell := Vector2i(-1, -1)
var hover_valid := false
var hover_tree_top_left := Vector2i(-1, -1)
var hover_tree_valid := false
var hover_stone_top_left := Vector2i(-1, -1)
var hover_stone_valid := false
var hover_build_top_left := Vector2i(-1, -1)
var hover_build_valid := false

func setup(main_node: Node, economy_node: Node) -> void:
	main = main_node
	economy = economy_node

func handle_build_click(world_pos: Vector2, mode: String) -> bool:
	if mode == "woodcutter":
		return _try_build_woodcutter_at(world_pos)
	if mode == "stonecutter":
		return _try_build_stonecutter_at(world_pos)
	if mode == "archery_range":
		return _try_build_archery_range_at(world_pos)
	if mode == "house":
		return _try_build_house_at(world_pos)
	if mode == "farm":
		return _try_build_farm_at(world_pos)
	if mode == "wood_storage":
		return _try_build_wood_storage_at(world_pos)
	if mode == "food_storage":
		return _try_build_food_storage_at(world_pos)
	if mode == "stone_storage":
		return _try_build_stone_storage_at(world_pos)
	return _place_tower_at(world_pos)

func update_hover(world_pos: Vector2, mode: String) -> void:
	var cell := Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not main._is_in_bounds(cell):
		if hover_cell != Vector2i(-1, -1):
			hover_cell = Vector2i(-1, -1)
			hover_tree_top_left = Vector2i(-1, -1)
			hover_stone_top_left = Vector2i(-1, -1)
			hover_build_top_left = Vector2i(-1, -1)
			main.queue_redraw()
		return
	hover_cell = cell
	if mode == "woodcutter":
		_update_tree_hover(cell)
		return
	if mode == "stonecutter":
		_update_stone_hover(cell)
		return
	if mode == "house" or mode == "farm" or mode == "wood_storage" or mode == "food_storage" or mode == "stone_storage":
		_update_building_hover(cell, mode)
		return
	if mode == "archery_range":
		_update_building_hover(cell, mode)
		return
	hover_tree_top_left = Vector2i(-1, -1)
	hover_valid = not main._is_path_cell(cell) \
		and not main._occupied.has(cell) \
		and not main._tree_by_cell.has(cell) \
		and not main._stone_by_cell.has(cell) \
		and not main._building_by_cell.has(cell) \
		and main._is_in_player_zone(cell)
	main.queue_redraw()

func draw_hover(drawer: Node2D, mode: String) -> void:
	if hover_cell == Vector2i(-1, -1):
		return
	if mode == "woodcutter":
		_draw_tree_hover(drawer)
		return
	if mode == "stonecutter":
		_draw_stone_hover(drawer)
		return
	if mode == "house" or mode == "farm" or mode == "wood_storage" or mode == "food_storage" or mode == "stone_storage":
		_draw_building_hover(drawer)
		return
	if mode == "archery_range":
		_draw_building_hover(drawer)
		return
	var color := Color(0.2, 0.8, 0.3, 0.5) if hover_valid else Color(0.9, 0.2, 0.2, 0.5)
	var rect := Rect2(hover_cell.x * main.cell_size, hover_cell.y * main.cell_size, main.cell_size, main.cell_size)
	drawer.draw_rect(rect, color, true)
	drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _update_tree_hover(cell: Vector2i) -> void:
	if not main._tree_by_cell.has(cell):
		hover_tree_top_left = Vector2i(-1, -1)
		main.queue_redraw()
		return
	var tree: Node2D = main._tree_by_cell[cell] as Node2D
	var top_left: Vector2i = tree.get("cell")
	hover_tree_top_left = top_left
	var has_cutter: bool = tree.get("has_cutter") == true
	hover_tree_valid = main._is_in_player_zone(cell) and not has_cutter and economy.can_afford_wood(main.woodcutter_cost)
	main.queue_redraw()

func _draw_tree_hover(drawer: Node2D) -> void:
	if hover_tree_top_left == Vector2i(-1, -1):
		return
	var color := Color(0.2, 0.8, 0.3, 0.4) if hover_tree_valid else Color(0.9, 0.2, 0.2, 0.4)
	var cells := [
		hover_tree_top_left,
		hover_tree_top_left + Vector2i(1, 0),
		hover_tree_top_left + Vector2i(0, 1),
		hover_tree_top_left + Vector2i(1, 1),
	]
	for cell in cells:
		var rect := Rect2(cell.x * main.cell_size, cell.y * main.cell_size, main.cell_size, main.cell_size)
		drawer.draw_rect(rect, color, true)
		drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _update_stone_hover(cell: Vector2i) -> void:
	if not main._stone_by_cell.has(cell):
		hover_stone_top_left = Vector2i(-1, -1)
		main.queue_redraw()
		return
	var stone: Node2D = main._stone_by_cell[cell] as Node2D
	var top_left: Vector2i = stone.get("cell")
	hover_stone_top_left = top_left
	var has_cutter: bool = stone.get("has_cutter") == true
	hover_stone_valid = main._is_in_player_zone(cell) and main._base_level >= 2 and not has_cutter and economy.can_afford_wood(main.stonecutter_cost)
	main.queue_redraw()

func _draw_stone_hover(drawer: Node2D) -> void:
	if hover_stone_top_left == Vector2i(-1, -1):
		return
	var color := Color(0.2, 0.8, 0.3, 0.4) if hover_stone_valid else Color(0.9, 0.2, 0.2, 0.4)
	var cells := [
		hover_stone_top_left,
		hover_stone_top_left + Vector2i(1, 0),
		hover_stone_top_left + Vector2i(0, 1),
		hover_stone_top_left + Vector2i(1, 1),
	]
	for cell in cells:
		var rect := Rect2(cell.x * main.cell_size, cell.y * main.cell_size, main.cell_size, main.cell_size)
		drawer.draw_rect(rect, color, true)
		drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _update_building_hover(cell: Vector2i, mode: String) -> void:
	hover_build_top_left = cell
	var has_resources := true
	if mode == "house":
		has_resources = economy.can_afford_wood(main.house_cost)
	elif mode == "farm":
		has_resources = economy.can_afford_wood(main.farm_cost)
	elif mode == "wood_storage":
		has_resources = economy.can_afford_wood(main.wood_storage_cost)
	elif mode == "food_storage":
		has_resources = economy.can_afford_wood(main.food_storage_cost)
	elif mode == "stone_storage":
		has_resources = economy.can_afford_wood(main.stone_storage_cost)
	elif mode == "archery_range":
		has_resources = economy.can_afford_wood(main.archery_range_cost)
	var size := 2
	if mode == "archery_range":
		size = 3
	hover_build_valid = _can_place_structure(cell, size) and has_resources
	main.queue_redraw()

func _draw_building_hover(drawer: Node2D) -> void:
	if hover_build_top_left == Vector2i(-1, -1):
		return
	var color := Color(0.2, 0.8, 0.3, 0.4) if hover_build_valid else Color(0.9, 0.2, 0.2, 0.4)
	var size := 2
	if main._build_mode == "archery_range":
		size = 3
	for x in range(size):
		for y in range(size):
			var cell := hover_build_top_left + Vector2i(x, y)
			var rect := Rect2(cell.x * main.cell_size, cell.y * main.cell_size, main.cell_size, main.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _place_tower_at(world_pos: Vector2) -> bool:
	var cell := Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not main._is_in_bounds(cell):
		return false
	if main._is_path_cell(cell):
		return false
	if main._tree_by_cell.has(cell):
		return false
	if main._stone_by_cell.has(cell):
		return false
	if main._building_by_cell.has(cell):
		return false
	if main._occupied.has(cell):
		return false
	if not main._is_in_player_zone(cell):
		return false
	if not economy.spend_wood(main.tower_cost):
		return false

	var tower := preload("res://scripts/Tower.gd").new()
	tower.cell = cell
	tower.cell_size = main.cell_size
	main.add_child(tower)
	main._occupied[cell] = tower
	return true

func _try_build_woodcutter_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not main._tree_by_cell.has(cell):
		return false
	if not main._is_in_player_zone(cell):
		return false
	var tree: Node2D = main._tree_by_cell[cell] as Node2D
	if tree.get("has_cutter") == true:
		return false
	if not economy.spend_wood(main.woodcutter_cost):
		return false
	_attach_woodcutter(tree)
	return true

func _try_build_stonecutter_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not main._stone_by_cell.has(cell):
		return false
	if main._base_level < 2:
		return false
	if not main._is_in_player_zone(cell):
		return false
	var stone: Node2D = main._stone_by_cell[cell] as Node2D
	if stone.get("has_cutter") == true:
		return false
	if not economy.spend_wood(main.stonecutter_cost):
		return false
	_attach_stonecutter(stone)
	return true

func _attach_woodcutter(tree: Node2D) -> void:
	var cutter := preload("res://scenes/Woodcutter.tscn").instantiate()
	cutter.cell_size = main.cell_size
	cutter.position = Vector2(main.cell_size, main.cell_size)
	cutter.wood_produced.connect(_on_wood_produced)
	tree.add_child(cutter)
	tree.set("has_cutter", true)

func _attach_stonecutter(stone: Node2D) -> void:
	var cutter := preload("res://scenes/Stonecutter.tscn").instantiate()
	cutter.cell_size = main.cell_size
	cutter.position = Vector2(main.cell_size, main.cell_size)
	cutter.stone_produced.connect(_on_stone_produced)
	stone.add_child(cutter)
	stone.set("has_cutter", true)

func _on_wood_produced(amount: int) -> void:
	economy.add_wood(amount)

func _on_stone_produced(amount: int) -> void:
	economy.add_stone(amount)

func _try_build_house_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not _can_place_structure(cell, 2):
		return false
	if not economy.spend_wood(main.house_cost):
		return false
	_place_structure("res://scenes/House.tscn", cell, 2)
	economy.add_unit_capacity(main.house_capacity)
	return true

func _try_build_farm_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not _can_place_structure(cell, 2):
		return false
	if not economy.spend_wood(main.farm_cost):
		return false
	var farm: Node2D = _place_structure("res://scenes/Farm.tscn", cell, 2)
	farm.food_produced.connect(_on_food_produced)
	return true

func _try_build_wood_storage_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not _can_place_structure(cell, 2):
		return false
	if not economy.spend_wood(main.wood_storage_cost):
		return false
	_place_structure("res://scenes/WoodStorage.tscn", cell, 2)
	economy.add_wood_cap(main.storage_capacity)
	return true

func _try_build_food_storage_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not _can_place_structure(cell, 2):
		return false
	if not economy.spend_wood(main.food_storage_cost):
		return false
	_place_structure("res://scenes/FoodStorage.tscn", cell, 2)
	economy.add_food_cap(main.storage_capacity)
	return true

func _try_build_stone_storage_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not _can_place_structure(cell, 2):
		return false
	if not economy.spend_wood(main.stone_storage_cost):
		return false
	_place_structure("res://scenes/StoneStorage.tscn", cell, 2)
	economy.add_stone_cap(main.storage_capacity)
	return true

func _try_build_archery_range_at(world_pos: Vector2) -> bool:
	var cell: Vector2i = Vector2i(int(world_pos.x / main.cell_size), int(world_pos.y / main.cell_size))
	if not _can_place_structure(cell, 3):
		return false
	if not economy.spend_wood(main.archery_range_cost):
		return false
	_place_structure("res://scenes/ArcheryRange.tscn", cell, 3)
	main._has_archery_range = true
	economy.update_buttons_for_base_level(main._base_level, main._has_archery_range)
	return true

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
			if main._tree_by_cell.has(cell):
				return false
			if main._stone_by_cell.has(cell):
				return false
			if main._building_by_cell.has(cell):
				return false
	return true

func _on_food_produced(amount: int) -> void:
	economy.add_food(amount)
