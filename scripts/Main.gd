extends Node2D

@export var grid_width := 64
@export var grid_height := 40
@export var cell_size := 64
@export var enable_path_edit := true
@export var spawn_interval := 1.5
@export var path_margin := 3
@export var auto_generate_path := true
@export var random_seed := 0
@export var path_straightness := 0.55
@export var path_max_vertical_step := 4
@export var path_length_multiplier := 2.0
@export var player_zone_width := 7
@export var tree_count := 18
@export var stone_count := 8
@export var starting_wood := 20
@export var starting_food := 0
@export var starting_stone := 0
@export var woodcutter_cost := 10
@export var stonecutter_cost := 15
@export var tower_cost := 10
@export var house_cost := 10
@export var farm_cost := 10
@export var wood_storage_cost := 10
@export var food_storage_cost := 10
@export var stone_storage_cost := 10
@export var house_capacity := 10
@export var unit_food_cost := 2
@export var stone_thrower_food_cost := 2
@export var stone_thrower_stone_cost := 1
@export var archer_food_cost := 3
@export var archer_wood_cost := 1
@export var archery_range_cost := 20
@export var archery_range_upgrade_cost := 30
@export var archery_range_upgrade_stone_cost := 10
@export var archery_range_upgrade_time := 12.0
@export var base_resource_cap := 50
@export var storage_capacity := 50
@export var base_upgrade_stone_cost := 100
@export var base_upgrade_cost := 100
@export var base_hp_upgrade := 15
@export var build_time_tower := 10.0
@export var build_time_woodcutter := 10.0
@export var build_time_stonecutter := 10.0
@export var build_time_house := 10.0
@export var build_time_farm := 10.0
@export var build_time_wood_storage := 10.0
@export var build_time_food_storage := 10.0
@export var build_time_stone_storage := 10.0
@export var build_time_archery_range := 10.0
@export var base_upgrade_times: Array[float] = [10.0, 15.0, 20.0]
@export var zone_upgrade_amount := 3
@export var restrict_path_to_base_band := false
@export var path_generation_attempts := 8

@export var path_cells: Array[Vector2i] = []

var _occupied := {}
var _enemy_timer: Timer
var _ordered_path_cells: Array[Vector2i] = []
var _path_valid := false
var _camera: Camera2D
var _camera_zoom := 1.0
var _camera_target := Vector2.ZERO
var _base_start: Base
var _base_end: Base
var _ui_layer: CanvasLayer
var _ui_builder: Node
var _hud_root: Control
var _splash_panel: PanelContainer
var _splash_play_button: Button
var _splash_exit_button: Button
var _pause_panel: PanelContainer
var _pause_resume_button: Button
var _pause_exit_button: Button
var _slider_straightness: HSlider
var _slider_vertical: HSlider
var _slider_length: HSlider
var _reset_button: Button
var _spawn_units_box: VBoxContainer
var _spawn_buttons: Dictionary = {}
var _unit_defs: Dictionary = {}
var _unit_catalog: Node
var _unit_spawner: Node
var _game_over_panel: PanelContainer
var _game_over_label: Label
var _game_over_button: Button
var _game_over_exit_button: Button
var _game_over := false
var _wood_label: Label
var _build_label: Label
var _base_label: Label
var _upgrade_button: Button
var _build_buttons_box: HBoxContainer
var _build_buttons: Dictionary = {}
var _building_catalog: Node
var _building_defs: Dictionary = {}
var _food_label: Label
var _stone_label: Label
var _unit_label: Label
var _economy: Node
var _placement: Node
var _trees: Array[Node2D] = []
var _tree_by_cell: Dictionary = {}
var _stones: Array[Node2D] = []
var _stone_by_cell: Dictionary = {}
var _resource_spawner: ResourceSpawner
var _building_by_cell: Dictionary = {}
var _build_mode := "tower"
var _has_archery_range := false
var _has_archery_range_upgrade := false
var _archery_ranges: Array[Node2D] = []
var _base_level := 1
var _base_start_cell := Vector2i(-1, -1)
var _base_end_cell := Vector2i(-1, -1)
var _base_upgrade_in_progress := false
var _splash_active := true
var _paused := false

func _ready() -> void:
	_setup_camera()
	_setup_ui_builder()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _ui_layer != null:
		_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_enemy_timer()
	_setup_economy()
	_setup_units()
	_setup_buildings()
	_setup_placement()
	_setup_resource_spawner()
	_update_base_label()
	if auto_generate_path and path_cells.is_empty():
		_generate_random_path()
	_rebuild_path()
	_resource_spawner.spawn_resources()
	_set_splash_active(true)
	queue_redraw()

func _exit_tree() -> void:
	_cleanup_runtime_nodes()
	_log_exit_diagnostics()

func _process(_delta: float) -> void:
	if _splash_active:
		return
	if _paused:
		return
	if _placement != null:
		_placement.update_hover(get_global_mouse_position(), _build_mode)
	_update_camera_controls(_delta)
	if _base_end != null and not _game_over:
		_update_base_upgrade_indicator()
	_update_archery_range_indicators()

func _unhandled_input(event: InputEvent) -> void:
	if _splash_active:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_set_paused(not _paused)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_camera_zoom = clampf(_camera_zoom * 1.1, 0.15, 2.5)
		_camera.zoom = Vector2(_camera_zoom, _camera_zoom)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_camera_zoom = clampf(_camera_zoom / 1.1, 0.15, 2.5)
		_camera.zoom = Vector2(_camera_zoom, _camera_zoom)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos := get_global_mouse_position()
		if enable_path_edit and event.shift_pressed:
			_add_path_cell(world_pos)
		else:
			if _is_over_player_base(world_pos):
				_try_upgrade_base()
				return
			var range := _get_archery_range_at(world_pos)
			if range != null:
				_try_upgrade_archery_range(range)
				return
			if _placement != null:
				_placement.handle_build_click(world_pos, _build_mode)
			return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if enable_path_edit and event.shift_pressed:
			_remove_path_cell(get_global_mouse_position())
		else:
			_set_build_mode("")

func _setup_ui_builder() -> void:
	var UiBuilderScript: Script = load("res://scripts/UiBuilder.gd")
	_ui_builder = UiBuilderScript.new()
	add_child(_ui_builder)
	_ui_builder.build(self)

func _setup_economy() -> void:
	var EconomyScript: Script = load("res://scripts/Economy.gd")
	_economy = EconomyScript.new()
	add_child(_economy)
	_economy.set_costs({
		"tower_cost": tower_cost,
		"woodcutter_cost": woodcutter_cost,
		"stonecutter_cost": stonecutter_cost,
		"archery_range_cost": archery_range_cost,
		"house_cost": house_cost,
		"farm_cost": farm_cost,
		"wood_storage_cost": wood_storage_cost,
		"food_storage_cost": food_storage_cost,
		"stone_storage_cost": stone_storage_cost,
		"base_upgrade_cost": base_upgrade_cost,
		"base_upgrade_stone_cost": base_upgrade_stone_cost,
		"stone_thrower_food_cost": stone_thrower_food_cost,
		"stone_thrower_stone_cost": stone_thrower_stone_cost,
		"archer_food_cost": archer_food_cost,
		"archer_wood_cost": archer_wood_cost,
	})
	_economy.set_labels(_wood_label, _food_label, _stone_label, _unit_label)
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range, _has_archery_range_upgrade)
	_economy.configure_resources(starting_wood, starting_food, starting_stone, base_resource_cap, unit_food_cost)
	_economy.set_base_upgrade_in_progress(_base_upgrade_in_progress)
	_economy.set_archery_range_upgrade(_has_archery_range_upgrade)

func _setup_units() -> void:
	var UnitCatalogScript: Script = load("res://scripts/UnitCatalog.gd")
	_unit_catalog = UnitCatalogScript.new()
	add_child(_unit_catalog)
	_unit_defs = _unit_catalog.build_defs(self)

	var UnitSpawnerScript: Script = load("res://scripts/UnitSpawner.gd")
	_unit_spawner = UnitSpawnerScript.new()
	add_child(_unit_spawner)
	_unit_spawner.setup(self, _economy)

	_build_spawn_buttons()
	_economy.set_unit_defs(_unit_defs)
	_economy.set_spawn_buttons(_spawn_buttons)
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range, _has_archery_range_upgrade)
	_economy.set_base_upgrade_in_progress(_base_upgrade_in_progress)

func _setup_buildings() -> void:
	var BuildingCatalogScript: Script = load("res://scripts/BuildingCatalog.gd")
	_building_catalog = BuildingCatalogScript.new()
	add_child(_building_catalog)
	_building_defs = _building_catalog.build_defs(self)
	_build_build_buttons()
	_economy.set_build_defs(_building_defs)
	_economy.set_build_buttons(_build_buttons, _upgrade_button)
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range, _has_archery_range_upgrade)

	var order: Array[String] = _building_catalog.get_order()
	if not order.is_empty():
		_set_build_mode(order[0])

func _setup_placement() -> void:
	var PlacementScript: Script = load("res://scripts/Placement.gd")
	_placement = PlacementScript.new()
	add_child(_placement)
	_placement.setup(self, _economy)

func _setup_resource_spawner() -> void:
	_resource_spawner = ResourceSpawner.new()
	add_child(_resource_spawner)
	_resource_spawner.setup(self)

func _build_build_buttons() -> void:
	if _build_buttons_box == null:
		return
	for child in _build_buttons_box.get_children():
		child.queue_free()
	_build_buttons.clear()
	var order: Array[String] = _building_catalog.get_order()
	for building_id in order:
		if not _building_defs.has(building_id):
			continue
		var def: Dictionary = _building_defs[building_id]
		var button := Button.new()
		var label: String = str(def.get("label", building_id))
		var cost_label: String = _building_cost_label(def)
		button.text = label if cost_label == "" else "%s (%s)" % [label, cost_label]
		button.pressed.connect(Callable(self, "_set_build_mode").bind(building_id))
		_build_buttons_box.add_child(button)
		_build_buttons[building_id] = button

func _building_cost_label(def: Dictionary) -> String:
	var parts: Array[String] = []
	var costs: Dictionary = def.get("costs", {})
	var food_cost: int = costs.get("food", 0)
	var wood_cost: int = costs.get("wood", 0)
	var stone_cost: int = costs.get("stone", 0)
	if food_cost > 0:
		parts.append("%dF" % food_cost)
	if wood_cost > 0:
		parts.append("%dW" % wood_cost)
	if stone_cost > 0:
		parts.append("%dS" % stone_cost)
	return "+".join(parts)

func _build_spawn_buttons() -> void:
	if _spawn_units_box == null:
		return
	for child in _spawn_units_box.get_children():
		child.queue_free()
	_spawn_buttons.clear()
	var order: Array[String] = _unit_catalog.get_order()
	for unit_id in order:
		if not _unit_defs.has(unit_id):
			continue
		var def: Dictionary = _unit_defs[unit_id]
		var button := Button.new()
		var label: String = str(def.get("label", unit_id))
		var cost_label: String = _unit_cost_label(def)
		button.text = label if cost_label == "" else "%s (%s)" % [label, cost_label]
		button.pressed.connect(Callable(self, "_spawn_unit_by_id").bind(unit_id))
		_spawn_units_box.add_child(button)
		_spawn_buttons[unit_id] = button

func _unit_cost_label(def: Dictionary) -> String:
	var parts: Array[String] = []
	var food_cost: int = def.get("food_cost", 0)
	var wood_cost: int = def.get("wood_cost", 0)
	var stone_cost: int = def.get("stone_cost", 0)
	if food_cost > 0:
		parts.append("%dF" % food_cost)
	if wood_cost > 0:
		parts.append("%dW" % wood_cost)
	if stone_cost > 0:
		parts.append("%dS" % stone_cost)
	return "+".join(parts)

func _spawn_unit_by_id(unit_id: String) -> void:
	if not _unit_defs.has(unit_id):
		return
	var def: Dictionary = _unit_defs[unit_id]
	if _unit_spawner == null:
		return
	_unit_spawner.spawn_unit(unit_id, def)

func set_path_cells(cells: Array[Vector2i]) -> void:
	path_cells = cells
	_rebuild_path()
	queue_redraw()

func _on_straightness_changed(value: float) -> void:
	path_straightness = value
	_reset_game()

func _on_vertical_step_changed(value: float) -> void:
	path_max_vertical_step = int(value)
	_reset_game()

func _on_length_changed(value: float) -> void:
	path_length_multiplier = value
	_reset_game()

func _on_reset_pressed() -> void:
	_reset_game()

func _reset_game() -> void:
	for node in get_tree().get_nodes_in_group("construction"):
		node.queue_free()
	_generate_random_path()
	_rebuild_path()
	if _resource_spawner != null:
		_resource_spawner.spawn_resources()
	_clear_units()
	_reset_bases()
	_base_upgrade_in_progress = false
	_game_over = false
	_game_over_panel.visible = false
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range, _has_archery_range_upgrade)
	_economy.set_base_upgrade_in_progress(false)
	_enemy_timer.start()
	queue_redraw()

func _cleanup_runtime_nodes() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		node.free()
	for node in get_tree().get_nodes_in_group("allies"):
		node.free()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.free()
	for node in get_tree().get_nodes_in_group("construction"):
		node.free()
	if _ui_layer != null and is_instance_valid(_ui_layer):
		_ui_layer.free()
	if _placement != null and is_instance_valid(_placement):
		_placement.free()
	if _economy != null and is_instance_valid(_economy):
		_economy.free()
	if _resource_spawner != null and is_instance_valid(_resource_spawner):
		_resource_spawner.free()

func _log_exit_diagnostics() -> void:
	var counts := {
		"nodes": get_tree().get_node_count(),
		"enemies": get_tree().get_nodes_in_group("enemies").size(),
		"allies": get_tree().get_nodes_in_group("allies").size(),
		"projectiles": get_tree().get_nodes_in_group("projectiles").size(),
		"construction": get_tree().get_nodes_in_group("construction").size(),
	}
	print("Exit diagnostics: %s" % counts)
	# Prints to help correlate with --verbose engine shutdown logs.
	for node in get_tree().get_nodes_in_group("enemies"):
		print("Exit leftover enemy: %s" % node)
	for node in get_tree().get_nodes_in_group("allies"):
		print("Exit leftover ally: %s" % node)
	for node in get_tree().get_nodes_in_group("projectiles"):
		print("Exit leftover projectile: %s" % node)
	for node in get_tree().get_nodes_in_group("construction"):
		print("Exit leftover construction: %s" % node)

func _clear_units() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("allies"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	_economy.reset_units()

func _reset_bases() -> void:
	if _base_start != null:
		_base_start.reset_hp()
	if _base_end != null:
		_base_end.reset_hp()

func _update_base_label() -> void:
	if _base_label != null:
		_base_label.text = _base_label_text()
	_update_upgrade_button_text()
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range, _has_archery_range_upgrade)
	_economy.set_base_upgrade_in_progress(_base_upgrade_in_progress)
	_update_base_upgrade_indicator()
	_economy.set_archery_range_upgrade(_has_archery_range_upgrade)

func _set_splash_active(active: bool) -> void:
	_splash_active = active
	if _hud_root != null:
		_hud_root.visible = not active
	if _splash_panel != null:
		_splash_panel.visible = active
	if _game_over_panel != null:
		_game_over_panel.visible = false
	if _enemy_timer != null:
		if active:
			_enemy_timer.stop()
		else:
			_enemy_timer.start()
	if active:
		_set_paused(false)

func _set_paused(active: bool) -> void:
	if _game_over:
		return
	_paused = active
	if _pause_panel != null:
		_pause_panel.visible = active
	get_tree().paused = active
	if _enemy_timer != null:
		if active:
			_enemy_timer.stop()
		else:
			_enemy_timer.start()

func _base_label_text() -> String:
	return "Base L%d | Zone: %d" % [_base_level, player_zone_width]

func _upgrade_button_text() -> String:
	if _base_level >= 2:
		return "Upgrade Base (100 Wood + 100 Stone)"
	return "Upgrade Base (100 Wood)"

func _update_upgrade_button_text() -> void:
	if _upgrade_button != null:
		_upgrade_button.text = _upgrade_button_text()

func _set_build_mode(mode: String) -> void:
	_build_mode = mode
	if _build_label != null:
		if _building_defs.has(mode):
			var def: Dictionary = _building_defs[mode]
			var label: String = str(def.get("label", mode))
			_build_label.text = "Build: %s" % label
		else:
			_build_label.text = "Build: "

func _on_upgrade_base_pressed() -> void:
	_try_upgrade_base()

func _try_upgrade_base() -> void:
	if _base_end == null:
		return
	if _base_upgrade_in_progress:
		return
	if not _economy.can_afford_wood(base_upgrade_cost):
		return
	if _base_level >= 2 and _economy.stone < base_upgrade_stone_cost:
		return
	_economy.spend_wood(base_upgrade_cost)
	if _base_level >= 2:
		_economy.spend_stone(base_upgrade_stone_cost)
	_base_upgrade_in_progress = true
	_economy.set_base_upgrade_in_progress(true)
	var top_left := _base_end_cell + Vector2i(-1, -1)
	var duration := _base_upgrade_duration()
	var construction = _spawn_construction(top_left, 3, duration)
	construction.completed.connect(_finish_base_upgrade)

func _base_upgrade_duration() -> float:
	if base_upgrade_times.is_empty():
		return 0.0
	var index: int = max(_base_level - 1, 0)
	if index >= base_upgrade_times.size():
		index = base_upgrade_times.size() - 1
	return base_upgrade_times[index]

func _finish_base_upgrade() -> void:
	_base_level += 1
	player_zone_width += zone_upgrade_amount
	_base_end.upgrade(base_hp_upgrade)
	_base_upgrade_in_progress = false
	_update_base_label()
	_update_enemy_spawn_rate()
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range, _has_archery_range_upgrade)
	_economy.set_base_upgrade_in_progress(false)
	_update_base_upgrade_indicator()
	_economy.set_archery_range_upgrade(_has_archery_range_upgrade)

func _generate_random_path() -> void:
	path_cells = []
	var start_x: int = path_margin
	var end_x: int = grid_width - 1 - path_margin
	if end_x <= start_x or grid_height <= 0:
		return

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	if random_seed == 0:
		rng.randomize()
	else:
		rng.seed = random_seed

	var attempt: int = 0
	while attempt < path_generation_attempts:
		_pick_base_cells(rng, start_x, end_x)
		if _base_start_cell == Vector2i(-1, -1) or _base_end_cell == Vector2i(-1, -1):
			attempt += 1
			continue

		var start: Vector2i = _base_start_cell
		var current: Vector2i = start
		var last_dir: Vector2i = Vector2i(1, 0)
		var vertical_streak: int = 0

		var path: Array[Vector2i] = []
		var visited: Dictionary[Vector2i, bool] = {}
		path.append(current)
		visited[current] = true

		var max_steps: int = grid_width * grid_height * 10
		var steps: int = 0

		while steps < max_steps:
			if current == _base_end_cell:
				path_cells = path
				return

			var candidates: Array[Vector2i] = _get_walk_candidates(current, start_x, end_x, visited, vertical_streak)
			if candidates.is_empty():
				if path.size() <= 1:
					break
				visited.erase(current)
				path.pop_back()
				current = path[path.size() - 1]
				vertical_streak = 0
				steps += 1
				continue

			var next: Vector2i = _choose_weighted_candidate(candidates, current, last_dir, rng)
			var dir: Vector2i = next - current
			if dir.y != 0:
				vertical_streak += 1
			else:
				vertical_streak = 0
			last_dir = dir
			current = next
			path.append(current)
			visited[current] = true
			steps += 1

		attempt += 1

	path_cells = _fallback_straight_path(_base_start_cell, _base_end_cell)

func _get_walk_candidates(
	current: Vector2i,
	start_x: int,
	end_x: int,
	visited: Dictionary[Vector2i, bool],
	vertical_streak: int
) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0)]
	var band := _base_band_bounds()
	for dir in dirs:
		if dir == Vector2i(-1, 0) and path_length_multiplier <= 1.0:
			continue
		if dir.y != 0 and vertical_streak >= path_max_vertical_step:
			continue
		var next: Vector2i = current + dir
		if next.x < start_x or next.x > end_x:
			continue
		if restrict_path_to_base_band:
			if next.y < band.x or next.y > band.y:
				continue
		if next.y < 0 or next.y >= grid_height:
			continue
		if visited.has(next):
			continue
		candidates.append(next)
	return candidates

func _choose_weighted_candidate(
	candidates: Array[Vector2i],
	current: Vector2i,
	last_dir: Vector2i,
	rng: RandomNumberGenerator
) -> Vector2i:
	var weights: Array[float] = []
	var total: float = 0.0
	for candidate in candidates:
		var dir: Vector2i = candidate - current
		var weight: float = _direction_weight(dir, last_dir)
		weights.append(weight)
		total += weight
	var pick: float = rng.randf() * total
	var acc: float = 0.0
	for i in range(candidates.size()):
		acc += weights[i]
		if pick <= acc:
			return candidates[i]
	return candidates[0]

func _direction_weight(dir: Vector2i, last_dir: Vector2i) -> float:
	var right_weight: float = lerp(2.0, 5.0, path_straightness)
	var vert_weight: float = lerp(2.5, 0.6, path_straightness) * maxf(1.0, path_length_multiplier)
	var left_weight: float = 0.0
	if path_length_multiplier > 1.0:
		left_weight = lerp(0.8, 0.1, path_straightness)

	var base: float = 0.01
	if dir == Vector2i(1, 0):
		base = right_weight
	elif dir == Vector2i(-1, 0):
		base = left_weight
	else:
		base = vert_weight

	var straight_bonus: float = 1.0
	if dir == last_dir:
		straight_bonus += path_straightness
	return maxf(0.01, base * straight_bonus)

func _fallback_straight_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var current := start
	path.append(current)
	while current.y != goal.y:
		current = Vector2i(current.x, current.y + signi(goal.y - current.y))
		path.append(current)
	while current.x != goal.x:
		current = Vector2i(current.x + signi(goal.x - current.x), current.y)
		path.append(current)
	return path

func _pick_base_cells(rng: RandomNumberGenerator, start_x: int, end_x: int) -> void:
	var band := _base_band_bounds()
	var start_y := rng.randi_range(band.x, band.y)
	var end_y := rng.randi_range(band.x, band.y)
	_base_start_cell = Vector2i(start_x, start_y)
	_base_end_cell = Vector2i(end_x, end_y)

func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_width and cell.y < grid_height

func _is_path_cell(cell: Vector2i) -> bool:
	return path_cells.has(cell)

func _draw() -> void:
	_draw_path()
	_draw_player_zone()
	_draw_grid()
	if _placement != null:
		_placement.draw_hover(self, _build_mode)

func _draw_grid() -> void:
	var grid_color := Color(0.2, 0.2, 0.2)
	var zoom := 1.0
	if _camera != null:
		zoom = _camera.zoom.x
	var line_width := maxf(1.0, 1.0 / zoom)
	for x in range(grid_width + 1):
		var from := Vector2(x * cell_size, 0)
		var to := Vector2(x * cell_size, grid_height * cell_size)
		draw_line(from, to, grid_color, line_width)
	for y in range(grid_height + 1):
		var from := Vector2(0, y * cell_size)
		var to := Vector2(grid_width * cell_size, y * cell_size)
		draw_line(from, to, grid_color, line_width)

func _draw_player_zone() -> void:
	var start_x: int = max(grid_width - player_zone_width, 0)
	var zone_color: Color = Color(0.2, 0.6, 0.25, 0.18)
	for x in range(start_x, grid_width):
		for y in range(grid_height):
			var rect := Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
			draw_rect(rect, zone_color, true)

func _draw_path() -> void:
	var painted_color := Color(0.9, 0.7, 0.2, 0.25)
	for cell in path_cells:
		var rect := Rect2(cell.x * cell_size, cell.y * cell_size, cell_size, cell_size)
		draw_rect(rect, painted_color, true)

	var ordered_color := Color(0.9, 0.7, 0.2, 0.6) if _path_valid else Color(0.9, 0.2, 0.2, 0.6)
	for cell in _ordered_path_cells:
		var rect := Rect2(cell.x * cell_size, cell.y * cell_size, cell_size, cell_size)
		draw_rect(rect, ordered_color, true)

func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)

func _get_archery_range_at(world_pos: Vector2) -> Node2D:
	for range in _archery_ranges:
		if range == null or not is_instance_valid(range):
			continue
		var size := cell_size * 3.0
		var local := world_pos - range.position
		if local.x >= 0.0 and local.y >= 0.0 and local.x <= size and local.y <= size:
			return range
	return null

func _try_upgrade_archery_range(range: Node2D) -> void:
	if range == null or not is_instance_valid(range):
		return
	if _has_archery_range_upgrade:
		return
	if range.get("level") != null and int(range.get("level")) >= 2:
		return
	if range.get("upgrade_in_progress") == true:
		return
	if not _economy.can_afford_wood(archery_range_upgrade_cost):
		return
	if _economy.stone < archery_range_upgrade_stone_cost:
		return
	_economy.spend_wood(archery_range_upgrade_cost)
	_economy.spend_stone(archery_range_upgrade_stone_cost)
	range.set("upgrade_in_progress", true)
	var top_left: Vector2i = range.get("cell")
	var construction = _spawn_construction(top_left, 3, archery_range_upgrade_time)
	construction.completed.connect(Callable(self, "_finish_archery_range_upgrade").bind(range))

func _finish_archery_range_upgrade(range: Node2D) -> void:
	if range == null or not is_instance_valid(range):
		return
	range.set("upgrade_in_progress", false)
	if range.has_method("upgrade"):
		range.call("upgrade")
	_has_archery_range_upgrade = true
	_economy.set_archery_range_upgrade(true)
	_update_archery_range_indicators()

func _update_archery_range_indicators() -> void:
	for range in _archery_ranges:
		if range == null or not is_instance_valid(range):
			continue
		var show: bool = not _has_archery_range_upgrade and range.get("upgrade_in_progress") != true
		var can_upgrade: bool = _economy.can_afford_wood(archery_range_upgrade_cost) and _economy.stone >= archery_range_upgrade_stone_cost
		if range.has_method("set_upgrade_indicator"):
			range.call("set_upgrade_indicator", show, can_upgrade)

func _register_archery_range(range: Node2D) -> void:
	_archery_ranges.append(range)
	_update_archery_range_indicators()

func _is_over_player_base(world_pos: Vector2) -> bool:
	if _base_end == null:
		return false
	var half := _base_end.size * 0.5
	var local := world_pos - _base_end.position
	return absf(local.x) <= half and absf(local.y) <= half

func _update_base_upgrade_indicator() -> void:
	if _base_end == null:
		return
	var can_upgrade: bool = _economy.can_afford_wood(base_upgrade_cost)
	if _base_level >= 2:
		can_upgrade = can_upgrade and _economy.stone >= base_upgrade_stone_cost
	var show := not _base_upgrade_in_progress
	_base_end.set_upgrade_indicator(show, can_upgrade)

func _spawn_construction(top_left: Vector2i, size: int, duration: float) -> Node2D:
	var ConstructionScript: Script = load("res://scripts/Construction.gd")
	var construction: Node2D = ConstructionScript.new()
	construction.cell_size = cell_size
	construction.size_cells = size
	construction.duration = duration
	construction.position = Vector2(top_left.x * cell_size, top_left.y * cell_size)
	add_child(construction)
	return construction

func _add_path_cell(world_pos: Vector2) -> void:
	var cell := Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))
	if not _is_in_bounds(cell):
		return
	if _occupied.has(cell):
		return
	if _tree_by_cell.has(cell):
		return
	if _stone_by_cell.has(cell):
		return
	if _building_by_cell.has(cell):
		return
	if _is_path_cell(cell):
		return
	path_cells.append(cell)
	_rebuild_path()
	queue_redraw()

func _remove_path_cell(world_pos: Vector2) -> void:
	var cell := Vector2i(int(world_pos.x / cell_size), int(world_pos.y / cell_size))
	if not _is_in_bounds(cell):
		return
	if not _is_path_cell(cell):
		return
	path_cells.erase(cell)
	_rebuild_path()
	queue_redraw()

func _setup_enemy_timer() -> void:
	_enemy_timer = Timer.new()
	_enemy_timer.wait_time = spawn_interval
	_enemy_timer.autostart = true
	_enemy_timer.timeout.connect(_spawn_enemy)
	add_child(_enemy_timer)
	_update_enemy_spawn_rate()

func _update_enemy_spawn_rate() -> void:
	if _enemy_timer == null:
		return
	var multiplier: float = 2.0 if _base_level >= 2 else 1.0
	_enemy_timer.wait_time = spawn_interval / multiplier

func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera_target = Vector2(grid_width * cell_size * 0.5, grid_height * cell_size * 0.5)
	_camera.position = _camera_target
	add_child(_camera)
	_camera.make_current()
	_update_camera_zoom()
	get_viewport().size_changed.connect(_update_camera_zoom)

func _update_camera_zoom() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var world_size: Vector2 = Vector2(grid_width * cell_size, grid_height * cell_size)
	if world_size.x <= 0 or world_size.y <= 0:
		return
	var zoom_scale: float = minf(viewport_size.x / world_size.x, viewport_size.y / world_size.y)
	if zoom_scale <= 0.0:
		return
	_camera_zoom = clampf(zoom_scale, 0.15, 1.5)
	_camera.zoom = Vector2(_camera_zoom, _camera_zoom)

func _update_camera_controls(delta: float) -> void:
	if _camera == null:
		return
	var speed := 600.0
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if input != Vector2.ZERO:
		_camera_target += input.normalized() * speed * delta
	_camera.position = _camera_target

func _spawn_enemy() -> void:
	if _splash_active:
		return
	if _game_over:
		return
	if not _path_valid:
		return
	var enemy: Node2D = preload("res://scenes/Enemy.tscn").instantiate() as Node2D
	enemy.path_points = _get_path_points()
	enemy.reached_goal.connect(_on_enemy_reached_goal.bind(enemy))
	add_child(enemy)

func _on_enemy_reached_goal(enemy: Node2D) -> void:
	if _base_end != null:
		_base_end.take_damage(1)
	if enemy != null and is_instance_valid(enemy):
		enemy.queue_free()

func _on_unit_reached_goal(unit: Node2D) -> void:
	if _base_start != null:
		_base_start.take_damage(1)
	_on_unit_removed(unit)

func _on_unit_removed(unit: Node2D) -> void:
	if unit != null and is_instance_valid(unit):
		unit.queue_free()
	_economy.on_unit_removed()

func _on_base_died(is_player_base: bool) -> void:
	if _game_over:
		return
	_game_over = true
	_enemy_timer.stop()
	for button in _spawn_buttons.values():
		var node := button as Button
		if node != null:
			node.disabled = true
	_game_over_panel.visible = true
	_game_over_label.text = "You Lose" if is_player_base else "You Win"

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene.call_deferred()

func _on_play_pressed() -> void:
	_set_splash_active(false)

func _on_resume_pressed() -> void:
	_set_paused(false)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _get_path_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for cell in _ordered_path_cells:
		points.append(_cell_to_world(cell))
	return points

func _get_path_points_reversed() -> Array[Vector2]:
	var points: Array[Vector2] = _get_path_points()
	points.reverse()
	return points

func _is_in_player_zone(cell: Vector2i) -> bool:
	return cell.x >= max(grid_width - player_zone_width, 0)

func _is_base_cell(cell: Vector2i) -> bool:
	for base_cell in _base_cells():
		if cell == base_cell:
			return true
	return false

func _base_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if _base_start_cell == Vector2i(-1, -1) or _base_end_cell == Vector2i(-1, -1):
		return cells
	for base_center in [_base_start_cell, _base_end_cell]:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var cell := Vector2i(base_center.x + dx, base_center.y + dy)
				if _is_in_bounds(cell):
					cells.append(cell)
	return cells

func _stone_band_bounds() -> Vector2i:
	var start_x: int = max(grid_width - player_zone_width - 10, 0)
	var end_x: int = max(grid_width - player_zone_width - 1, 0)
	if end_x < start_x:
		end_x = start_x
	return Vector2i(start_x, end_x)

func _is_in_stone_band(cell: Vector2i) -> bool:
	var band: Vector2i = _stone_band_bounds()
	return cell.x >= band.x and cell.x <= band.y

func _is_in_base_band(cell: Vector2i) -> bool:
	var band := _base_band_bounds()
	return cell.y >= band.x and cell.y <= band.y

func _base_band_bounds() -> Vector2i:
	var min_y: int = int(floor(grid_height / 3.0))
	var max_y: int = int(floor(2.0 * grid_height / 3.0)) - 1
	if max_y < min_y:
		min_y = 0
		max_y = grid_height - 1
	return Vector2i(min_y, max_y)

func _rebuild_path() -> void:
	_ordered_path_cells = []
	_path_valid = false
	if path_cells.is_empty():
		_clear_bases()
		return

	var walkable: Dictionary[Vector2i, bool] = {}
	for cell in path_cells:
		walkable[cell] = true

	var starts: Array[Vector2i] = []
	if _base_start_cell != Vector2i(-1, -1) and _base_end_cell != Vector2i(-1, -1):
		if walkable.has(_base_start_cell) and walkable.has(_base_end_cell):
			starts.append(_base_start_cell)
	else:
		for cell in path_cells:
			if cell.x == path_margin and _is_in_base_band(cell):
				starts.append(cell)
	if starts.is_empty():
		_clear_bases()
		return

	var frontier: Array[Vector2i] = starts.duplicate()
	var came_from: Dictionary[Vector2i, Vector2i] = {}
	for start in starts:
		came_from[start] = Vector2i(-999, -999)

	var goal := Vector2i(-1, -1)
	if _base_start_cell != Vector2i(-1, -1) and _base_end_cell != Vector2i(-1, -1):
		goal = _base_end_cell
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front() as Vector2i
		if goal != Vector2i(-1, -1):
			if current == goal:
				break
		elif current.x == grid_width - 1 - path_margin and _is_in_base_band(current):
			goal = current
			break
		for dir in directions:
			var next: Vector2i = current + dir
			if not walkable.has(next):
				continue
			if came_from.has(next):
				continue
			came_from[next] = current
			frontier.append(next)

	if goal == Vector2i(-1, -1):
		_clear_bases()
		return

	var path_rev: Array[Vector2i] = []
	var step: Vector2i = goal
	while step != Vector2i(-999, -999):
		path_rev.append(step)
		step = came_from[step]

	path_rev.reverse()
	_ordered_path_cells = path_rev
	_path_valid = true
	_update_bases()

func _update_bases() -> void:
	if not _path_valid or _ordered_path_cells.is_empty():
		_clear_bases()
		return

	var start_cell := _ordered_path_cells[0]
	var end_cell := _ordered_path_cells[_ordered_path_cells.size() - 1]

	if _base_start == null:
		_base_start = preload("res://scenes/Base.tscn").instantiate() as Base
		add_child(_base_start)
	_base_start.size = cell_size * 3
	_base_start.position = _cell_to_world(start_cell)
	if not _base_start.died.is_connected(_on_base_died):
		_base_start.died.connect(_on_base_died.bind(false))

	if _base_end == null:
		_base_end = preload("res://scenes/Base.tscn").instantiate() as Base
		add_child(_base_end)
	_base_end.size = cell_size * 3
	_base_end.position = _cell_to_world(end_cell)
	_base_end.is_goal = true
	if not _base_end.died.is_connected(_on_base_died):
		_base_end.died.connect(_on_base_died.bind(true))

func _clear_bases() -> void:
	if _base_start != null:
		_base_start.queue_free()
		_base_start = null
	if _base_end != null:
		_base_end.queue_free()
		_base_end = null
