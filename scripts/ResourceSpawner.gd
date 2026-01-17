extends Node
class_name ResourceSpawner

var main: Node
var rng: RandomNumberGenerator

func setup(main_node: Node) -> void:
	main = main_node
	rng = RandomNumberGenerator.new()

func spawn_resources() -> void:
	_clear_trees()
	_clear_stones()
	var has_tree_in_zone: bool = _spawn_trees()
	if not has_tree_in_zone:
		_find_any_player_zone_cell()
	var has_stone_in_band: bool = _spawn_stones()
	if not has_stone_in_band:
		_find_any_stone_band_cell()

func _clear_trees() -> void:
	for tree in main._trees:
		if tree != null and is_instance_valid(tree):
			tree.queue_free()
	main._trees.clear()
	main._tree_by_cell.clear()

func _spawn_trees() -> bool:
	if main.grid_width < 2 or main.grid_height < 2:
		return false

	_seed_rng(97)

	var attempts: int = 0
	var placed: int = 0
	var ensured: bool = false
	var max_attempts: int = main.tree_count * 20
	while placed < main.tree_count and attempts < max_attempts:
		var in_player_zone: bool = not ensured
		var cell: Vector2i = _pick_tree_cell(in_player_zone)
		attempts += 1
		if cell == Vector2i(-1, -1):
			continue
		if _place_tree(cell):
			placed += 1
			if main._is_in_player_zone(cell):
				ensured = true
	return ensured

func _spawn_stones() -> bool:
	if main.grid_width < 2 or main.grid_height < 2:
		return false

	_seed_rng(181)

	var attempts: int = 0
	var placed: int = 0
	var ensured: bool = false
	var max_attempts: int = main.stone_count * 20
	while placed < main.stone_count and attempts < max_attempts:
		var require_band: bool = not ensured
		var cell: Vector2i = _pick_stone_cell(require_band)
		attempts += 1
		if cell == Vector2i(-1, -1):
			continue
		if _place_stone(cell):
			placed += 1
			if main._is_in_stone_band(cell):
				ensured = true
	return ensured

func _clear_stones() -> void:
	for stone in main._stones:
		if stone != null and is_instance_valid(stone):
			stone.queue_free()
	main._stones.clear()
	main._stone_by_cell.clear()

func _pick_tree_cell(in_player_zone: bool) -> Vector2i:
	var min_x: int = 0
	var max_x: int = main.grid_width - 2
	var min_y: int = 0
	var max_y: int = main.grid_height - 2
	if in_player_zone:
		min_x = max(main.grid_width - main.player_zone_width, 0)
		max_x = max(main.grid_width - 2, 0)
	if max_x < min_x or max_y < min_y:
		return Vector2i(-1, -1)
	var x: int = rng.randi_range(min_x, max_x)
	var y: int = rng.randi_range(min_y, max_y)
	return Vector2i(x, y)

func _place_tree(top_left: Vector2i) -> bool:
	var cells: Array[Vector2i] = [
		top_left,
		top_left + Vector2i(1, 0),
		top_left + Vector2i(0, 1),
		top_left + Vector2i(1, 1),
	]
	for cell in cells:
		if not main._is_in_bounds(cell):
			return false
		if main._is_base_cell(cell):
			return false
		if main._is_path_cell(cell):
			return false
		if main._stone_by_cell.has(cell):
			return false
		if main._tree_by_cell.has(cell):
			return false
	var tree: Node2D = preload("res://scenes/Tree.tscn").instantiate() as Node2D
	tree.set("cell", top_left)
	tree.set("cell_size", main.cell_size)
	main.add_child(tree)
	main._trees.append(tree)
	for cell in cells:
		main._tree_by_cell[cell] = tree
	return true

func _find_any_player_zone_cell() -> bool:
	var min_x: int = max(main.grid_width - main.player_zone_width, 0)
	var max_x: int = max(main.grid_width - 2, 0)
	for y in range(main.grid_height - 1):
		for x in range(min_x, max_x + 1):
			if _place_tree(Vector2i(x, y)):
				return true
	return false

func _pick_stone_cell(require_band: bool) -> Vector2i:
	var min_x: int = 0
	var max_x: int = main.grid_width - 2
	var min_y: int = 0
	var max_y: int = main.grid_height - 2
	if require_band:
		var band: Vector2i = main._stone_band_bounds()
		min_x = band.x
		max_x = band.y
	if max_x < min_x or max_y < min_y:
		return Vector2i(-1, -1)
	var x: int = rng.randi_range(min_x, max_x)
	var y: int = rng.randi_range(min_y, max_y)
	return Vector2i(x, y)

func _place_stone(top_left: Vector2i) -> bool:
	var cells: Array[Vector2i] = [
		top_left,
		top_left + Vector2i(1, 0),
		top_left + Vector2i(0, 1),
		top_left + Vector2i(1, 1),
	]
	for cell in cells:
		if not main._is_in_bounds(cell):
			return false
		if main._is_base_cell(cell):
			return false
		if main._is_path_cell(cell):
			return false
		if main._tree_by_cell.has(cell):
			return false
		if main._stone_by_cell.has(cell):
			return false
	var stone: Node2D = preload("res://scenes/Stone.tscn").instantiate() as Node2D
	stone.set("cell", top_left)
	stone.set("cell_size", main.cell_size)
	main.add_child(stone)
	main._stones.append(stone)
	for cell in cells:
		main._stone_by_cell[cell] = stone
	return true

func _find_any_stone_band_cell() -> bool:
	var band: Vector2i = main._stone_band_bounds()
	for y in range(main.grid_height - 1):
		for x in range(band.x, band.y + 1):
			if _place_stone(Vector2i(x, y)):
				return true
	return false

func _seed_rng(offset: int) -> void:
	if main.random_seed == 0:
		rng.randomize()
	else:
		rng.seed = main.random_seed + offset
