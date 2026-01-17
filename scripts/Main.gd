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
@export var archery_range_cost := 20
@export var base_resource_cap := 50
@export var storage_capacity := 50
@export var base_upgrade_stone_cost := 100
@export var base_upgrade_cost := 100
@export var base_hp_upgrade := 15
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
var _slider_straightness: HSlider
var _slider_vertical: HSlider
var _slider_length: HSlider
var _reset_button: Button
var _spawn_unit_button: Button
var _spawn_stone_thrower_button: Button
var _game_over_panel: PanelContainer
var _game_over_label: Label
var _game_over_button: Button
var _game_over := false
var _wood_label: Label
var _build_label: Label
var _base_label: Label
var _tower_button: Button
var _woodcutter_button: Button
var _stonecutter_button: Button
var _archery_range_button: Button
var _upgrade_button: Button
var _house_button: Button
var _farm_button: Button
var _wood_storage_button: Button
var _food_storage_button: Button
var _stone_storage_button: Button
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
var _base_level := 1
var _base_start_cell := Vector2i(-1, -1)
var _base_end_cell := Vector2i(-1, -1)

func _ready() -> void:
	_setup_camera()
	_setup_ui()
	_setup_enemy_timer()
	_setup_economy()
	_setup_placement()
	_setup_resource_spawner()
	_update_base_label()
	if auto_generate_path and path_cells.is_empty():
		_generate_random_path()
	_rebuild_path()
	_resource_spawner.spawn_resources()
	queue_redraw()

func _process(_delta: float) -> void:
	_placement.update_hover(get_global_mouse_position(), _build_mode)
	_update_camera_controls(_delta)

func _unhandled_input(event: InputEvent) -> void:
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
			_placement.handle_build_click(world_pos, _build_mode)
			return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if enable_path_edit and event.shift_pressed:
			_remove_path_cell(get_global_mouse_position())

func _setup_ui() -> void:
	_ui_layer = CanvasLayer.new()
	add_child(_ui_layer)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.size = Vector2(320, 420)
	_ui_layer.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	_wood_label = Label.new()
	_wood_label.text = "Wood: 0 / 0"
	vbox.add_child(_wood_label)

	_food_label = Label.new()
	_food_label.text = "Food: 0 / 0"
	vbox.add_child(_food_label)

	_stone_label = Label.new()
	_stone_label.text = "Stone: 0 / 0"
	vbox.add_child(_stone_label)

	_unit_label = Label.new()
	_unit_label.text = "Units: 0 / 0"
	vbox.add_child(_unit_label)

	_build_label = Label.new()
	_build_label.text = "Build: Tower"

	_base_label = Label.new()
	_base_label.text = _base_label_text()
	vbox.add_child(_base_label)

	var title: Label = Label.new()
	title.text = "Path Generator"
	vbox.add_child(title)

	var straight_label: Label = Label.new()
	straight_label.text = "Straightness"
	vbox.add_child(straight_label)

	_slider_straightness = HSlider.new()
	_slider_straightness.min_value = 0.0
	_slider_straightness.max_value = 1.0
	_slider_straightness.step = 0.05
	_slider_straightness.value = path_straightness
	_slider_straightness.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_straightness.value_changed.connect(_on_straightness_changed)
	vbox.add_child(_slider_straightness)

	var vertical_label: Label = Label.new()
	vertical_label.text = "Max Vertical Step"
	vbox.add_child(vertical_label)

	_slider_vertical = HSlider.new()
	_slider_vertical.min_value = 1.0
	_slider_vertical.max_value = 12.0
	_slider_vertical.step = 1.0
	_slider_vertical.value = float(path_max_vertical_step)
	_slider_vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_vertical.value_changed.connect(_on_vertical_step_changed)
	vbox.add_child(_slider_vertical)

	var length_label: Label = Label.new()
	length_label.text = "Length Multiplier"
	vbox.add_child(length_label)

	_slider_length = HSlider.new()
	_slider_length.min_value = 1.0
	_slider_length.max_value = 3.0
	_slider_length.step = 0.1
	_slider_length.value = path_length_multiplier
	_slider_length.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_slider_length.value_changed.connect(_on_length_changed)
	vbox.add_child(_slider_length)

	_reset_button = Button.new()
	_reset_button.text = "Reset (Regen Path)"
	_reset_button.pressed.connect(_on_reset_pressed)
	vbox.add_child(_reset_button)

	var unit_label: Label = Label.new()
	unit_label.text = "Units"
	vbox.add_child(unit_label)

	_spawn_unit_button = Button.new()
	_spawn_unit_button.text = "Grunt (%d)" % unit_food_cost
	_spawn_unit_button.pressed.connect(_on_spawn_unit_pressed)
	# moved to right panel

	_spawn_stone_thrower_button = Button.new()
	_spawn_stone_thrower_button.text = "Stone Thrower (%dF+%dS)" % [stone_thrower_food_cost, stone_thrower_stone_cost]
	_spawn_stone_thrower_button.pressed.connect(_on_spawn_stone_thrower_pressed)
	# moved to right panel


	_tower_button = Button.new()
	_tower_button.text = "Place Tower (10)"
	_tower_button.pressed.connect(_on_place_tower_pressed)
	# moved to bottom panel

	_woodcutter_button = Button.new()
	_woodcutter_button.text = "Place Woodcutter (10)"
	_woodcutter_button.pressed.connect(_on_place_woodcutter_pressed)
	# moved to bottom panel

	_stonecutter_button = Button.new()
	_stonecutter_button.text = "Place Stonecutter (15)"
	_stonecutter_button.pressed.connect(_on_place_stonecutter_pressed)
	# moved to bottom panel

	_archery_range_button = Button.new()
	_archery_range_button.text = "Place Archery Range (20)"
	_archery_range_button.pressed.connect(_on_place_archery_range_pressed)
	# moved to bottom panel

	_house_button = Button.new()
	_house_button.text = "Place House (10)"
	_house_button.pressed.connect(_on_place_house_pressed)
	# moved to bottom panel

	_farm_button = Button.new()
	_farm_button.text = "Place Farm (10)"
	_farm_button.pressed.connect(_on_place_farm_pressed)
	# moved to bottom panel

	_wood_storage_button = Button.new()
	_wood_storage_button.text = "Place Wood Storage (10)"
	_wood_storage_button.pressed.connect(_on_place_wood_storage_pressed)
	# moved to bottom panel

	_food_storage_button = Button.new()
	_food_storage_button.text = "Place Food Storage (10)"
	_food_storage_button.pressed.connect(_on_place_food_storage_pressed)
	# moved to bottom panel

	_stone_storage_button = Button.new()
	_stone_storage_button.text = "Place Stone Storage (10)"
	_stone_storage_button.pressed.connect(_on_place_stone_storage_pressed)
	# moved to bottom panel

	var upgrade_label: Label = Label.new()
	upgrade_label.text = "Base"
	vbox.add_child(upgrade_label)

	_upgrade_button = Button.new()
	_upgrade_button.text = _upgrade_button_text()
	_upgrade_button.pressed.connect(_on_upgrade_base_pressed)
	vbox.add_child(_upgrade_button)

	_game_over_panel = PanelContainer.new()
	_game_over_panel.visible = false
	_game_over_panel.size = Vector2(360, 160)
	_game_over_panel.anchor_left = 0.5
	_game_over_panel.anchor_top = 0.5
	_game_over_panel.anchor_right = 0.5
	_game_over_panel.anchor_bottom = 0.5
	_game_over_panel.offset_left = -180
	_game_over_panel.offset_top = -80
	_game_over_panel.offset_right = 180
	_game_over_panel.offset_bottom = 80
	_ui_layer.add_child(_game_over_panel)

	var game_over_box: VBoxContainer = VBoxContainer.new()
	game_over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_over_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_over_box.add_theme_constant_override("separation", 10)
	_game_over_panel.add_child(game_over_box)

	_game_over_label = Label.new()
	_game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over_label.text = ""
	game_over_box.add_child(_game_over_label)

	_game_over_button = Button.new()
	_game_over_button.text = "Restart"
	_game_over_button.pressed.connect(_on_restart_pressed)
	game_over_box.add_child(_game_over_button)

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
	})
	_economy.set_labels(_wood_label, _food_label, _stone_label, _unit_label)
	_economy.set_buttons(
		_spawn_unit_button,
		_spawn_stone_thrower_button,
		_tower_button,
		_woodcutter_button,
		_stonecutter_button,
		_archery_range_button,
		_house_button,
		_farm_button,
		_wood_storage_button,
		_food_storage_button,
		_stone_storage_button,
		_upgrade_button
	)
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range)
	_economy.configure_resources(starting_wood, starting_food, starting_stone, base_resource_cap, unit_food_cost)

func _setup_placement() -> void:
	var PlacementScript: Script = load("res://scripts/Placement.gd")
	_placement = PlacementScript.new()
	add_child(_placement)
	_placement.setup(self, _economy)

func _setup_resource_spawner() -> void:
	_resource_spawner = ResourceSpawner.new()
	add_child(_resource_spawner)
	_resource_spawner.setup(self)

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_top = 0.5
	right_panel.anchor_bottom = 0.5
	right_panel.offset_left = -220
	right_panel.offset_right = -20
	right_panel.offset_top = -60
	right_panel.offset_bottom = 60
	_ui_layer.add_child(right_panel)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_panel.add_child(right_box)
	var spawn_label: Label = Label.new()
	spawn_label.text = "Spawn Units"
	right_box.add_child(spawn_label)
	right_box.add_child(_spawn_unit_button)
	right_box.add_child(_spawn_stone_thrower_button)

	var bottom_panel: PanelContainer = PanelContainer.new()
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 16
	bottom_panel.offset_right = -16
	bottom_panel.offset_top = -96
	bottom_panel.offset_bottom = -16
	_ui_layer.add_child(bottom_panel)

	var bottom_box: VBoxContainer = VBoxContainer.new()
	bottom_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_box.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_box)

	var build_header: Label = Label.new()
	build_header.text = "Buildings"
	bottom_box.add_child(build_header)
	bottom_box.add_child(_build_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(button_row)
	button_row.add_child(_tower_button)
	button_row.add_child(_woodcutter_button)
	button_row.add_child(_stonecutter_button)
	button_row.add_child(_archery_range_button)
	button_row.add_child(_house_button)
	button_row.add_child(_farm_button)
	button_row.add_child(_wood_storage_button)
	button_row.add_child(_food_storage_button)
	button_row.add_child(_stone_storage_button)

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
	_generate_random_path()
	_rebuild_path()
	if _resource_spawner != null:
		_resource_spawner.spawn_resources()
	_clear_units()
	_reset_bases()
	_game_over = false
	_game_over_panel.visible = false
	_spawn_unit_button.disabled = false
	_enemy_timer.start()
	queue_redraw()

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
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range)

func _base_label_text() -> String:
	return "Base L%d | Zone: %d" % [_base_level, player_zone_width]

func _upgrade_button_text() -> String:
	if _base_level >= 2:
		return "Upgrade Base (100 Wood + 100 Stone)"
	return "Upgrade Base (100 Wood)"

func _update_upgrade_button_text() -> void:
	if _upgrade_button != null:
		_upgrade_button.text = _upgrade_button_text()

func _on_spawn_unit_pressed() -> void:
	_spawn_friendly_unit()

func _on_spawn_stone_thrower_pressed() -> void:
	_spawn_stone_thrower()

func _on_place_tower_pressed() -> void:
	_set_build_mode("tower")

func _on_place_woodcutter_pressed() -> void:
	_set_build_mode("woodcutter")

func _on_place_stonecutter_pressed() -> void:
	_set_build_mode("stonecutter")

func _on_place_archery_range_pressed() -> void:
	_set_build_mode("archery_range")

func _on_place_house_pressed() -> void:
	_set_build_mode("house")

func _on_place_farm_pressed() -> void:
	_set_build_mode("farm")

func _on_place_wood_storage_pressed() -> void:
	_set_build_mode("wood_storage")

func _on_place_food_storage_pressed() -> void:
	_set_build_mode("food_storage")

func _on_place_stone_storage_pressed() -> void:
	_set_build_mode("stone_storage")

func _set_build_mode(mode: String) -> void:
	_build_mode = mode
	if _build_label != null:
		if mode == "woodcutter":
			_build_label.text = "Build: Woodcutter"
		elif mode == "stonecutter":
			_build_label.text = "Build: Stonecutter"
		elif mode == "archery_range":
			_build_label.text = "Build: Archery Range"
		elif mode == "house":
			_build_label.text = "Build: House"
		elif mode == "farm":
			_build_label.text = "Build: Farm"
		elif mode == "wood_storage":
			_build_label.text = "Build: Wood Storage"
		elif mode == "food_storage":
			_build_label.text = "Build: Food Storage"
		elif mode == "stone_storage":
			_build_label.text = "Build: Stone Storage"
		else:
			_build_label.text = "Build: Tower"

func _on_upgrade_base_pressed() -> void:
	if _base_end == null:
		return
	if not _economy.can_afford_wood(base_upgrade_cost):
		return
	if _base_level >= 2 and _economy.stone < base_upgrade_stone_cost:
		return
	_economy.spend_wood(base_upgrade_cost)
	if _base_level >= 2:
		_economy.spend_stone(base_upgrade_stone_cost)
	_base_level += 1
	player_zone_width += zone_upgrade_amount
	_base_end.upgrade(base_hp_upgrade)
	_update_base_label()
	_update_enemy_spawn_rate()
	_economy.update_buttons_for_base_level(_base_level, _has_archery_range)

func _spawn_friendly_unit() -> void:
	if _game_over:
		return
	if not _path_valid or _ordered_path_cells.is_empty():
		return
	if not _economy.can_spawn_unit():
		return
	_economy.on_unit_spawned()
	var unit: Node2D = preload("res://scenes/Grunt.tscn").instantiate() as Node2D
	unit.path_points = _get_path_points_reversed()
	unit.reached_goal.connect(_on_unit_reached_goal.bind(unit))
	unit.died.connect(_on_unit_removed.bind(unit))
	add_child(unit)

func _spawn_stone_thrower() -> void:
	if _game_over:
		return
	if not _path_valid or _ordered_path_cells.is_empty():
		return
	if not _has_archery_range:
		return
	if not _economy.can_spawn_stone_thrower():
		return
	_economy.on_stone_thrower_spawned()
	var unit: Node2D = preload("res://scenes/StoneThrower.tscn").instantiate() as Node2D
	unit.path_points = _get_path_points_reversed()
	unit.reached_goal.connect(_on_unit_reached_goal.bind(unit))
	unit.died.connect(_on_unit_removed.bind(unit))
	add_child(unit)

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
	_spawn_unit_button.disabled = true
	_game_over_panel.visible = true
	_game_over_label.text = "You Lose" if is_player_base else "You Win"

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

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
	_base_start.position = _cell_to_world(start_cell)
	if not _base_start.died.is_connected(_on_base_died):
		_base_start.died.connect(_on_base_died.bind(false))

	if _base_end == null:
		_base_end = preload("res://scenes/Base.tscn").instantiate() as Base
		add_child(_base_end)
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
