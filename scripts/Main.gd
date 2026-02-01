extends Node2D

const GameConfig = preload("res://scripts/GameConfig.gd")
const GameWorld = preload("res://scripts/state/GameWorld.gd")
const UiController = preload("res://scripts/UiController.gd")
const PerformanceTracker = preload("res://scripts/PerformanceTracker.gd")

@export var config: GameConfig = GameConfig.new()
@export var fog_color: Color = Color(0.05, 0.05, 0.1, 0.85)

# GameWorld holds all game state
var _world: GameWorld

# Manager references
var _enemy_timer: Timer
var _camera_controller: Node
var _ui_layer: CanvasLayer
var _ui_builder: Node
var _ui_controller: UiController
var _unit_catalog: Node
var _unit_spawner: Node
var _building_catalog: Node
var _economy: Node
var _placement: Node
var _resource_catalog: Node
var _resource_spawner: ResourceSpawner
var _path_generator: Node
var _game_state_manager: Node
var _upgrade_manager: Node
var _map_editor: Node
var _performance_tracker: PerformanceTracker
var _campaign_controller: Node

# UI-related state
var _spawn_buttons: Dictionary = {}
var _unit_defs: Dictionary = {}
var _upgrade_button: Button
var _build_category_buttons: Dictionary = {}
var _build_category := ""
var _build_buttons: Dictionary = {}
var _building_defs: Dictionary = {}
var _build_mode := "grunt_tower"
var _editor_active := false

func _ready() -> void:
	if config == null:
		config = GameConfig.new()
	elif not config.resource_local_to_scene:
		config = config.duplicate() as GameConfig
		config.resource_local_to_scene = true

	# Create GameWorld container
	_world = GameWorld.new(config)
	_world.fog.color = fog_color

	_setup_camera_controller()
	_setup_resource_catalog()
	_setup_economy()
	_setup_upgrade_manager()
	_setup_ui_builder()
	_setup_performance_tracker()
	if _ui_controller != null:
		_economy.set_labels(
			_ui_controller.wood_label,
			_ui_controller.food_label,
			_ui_controller.stone_label,
			_ui_controller.iron_label,
			_ui_controller.unit_label
		)
	_upgrade_manager._sync_ui_refs()
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _ui_layer != null:
		_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_enemy_timer()
	_setup_game_state_manager()
	_setup_units()
	_setup_buildings()
	_setup_placement()
	_setup_resource_spawner()
	_setup_path_generator()
	_setup_map_editor()
	_map_editor.update_tool_label()
	_map_editor.refresh_map_list()
	_update_base_label()
	if config.auto_generate_path and _world.path.cells.is_empty():
		_generate_random_path()
	_rebuild_path()
	_resource_spawner.spawn_resources()
	_reset_fog()
	_game_state_manager.set_splash_active(true)
	queue_redraw()

func _exit_tree() -> void:
	_cleanup_runtime_nodes()
	_log_exit_diagnostics()

func _process(_delta: float) -> void:
	if _game_state_manager.is_splash_active():
		return
	if _game_state_manager.is_paused():
		return
	_update_fog_progression()
	if _editor_active:
		if _camera_controller != null:
			_camera_controller.update(_delta, true)
		queue_redraw()
		return
	if _ui_controller != null and _ui_controller.upgrade_modal != null and _ui_controller.upgrade_modal.visible:
		_upgrade_manager.update_upgrade_modal()
	if _placement != null:
		_placement.update_hover(get_global_mouse_position(), _build_mode)
	if _camera_controller != null:
		_camera_controller.update(_delta, false)
	if _world.bases.end != null and not _game_state_manager.is_game_over():
		_update_base_upgrade_indicator()
	_update_archery_range_indicators()
	_update_stats_panel()

func _unhandled_input(event: InputEvent) -> void:
	if _game_state_manager.is_splash_active():
		return
	if event is InputEventMouseButton and _camera_controller != null:
		_camera_controller.handle_zoom_input(event)
	if _editor_active:
		_map_editor.handle_input(event)
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_game_state_manager.set_paused(not _game_state_manager.is_paused())
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var world_pos := get_global_mouse_position()
		if config.enable_path_edit and event.shift_pressed:
			_add_path_cell(world_pos)
		else:
			if _is_over_player_base(world_pos):
				_upgrade_manager.show_upgrade_modal("base", _world.bases.end)
				return
			var range := _get_archery_range_at(world_pos)
			if range != null:
				_upgrade_manager.show_upgrade_modal("archery_range", range)
				return
			if _placement != null:
				_placement.handle_build_click(world_pos, _build_mode)
			return
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if config.enable_path_edit and event.shift_pressed:
			_remove_path_cell(get_global_mouse_position())
		else:
			_set_build_mode("")

# Setup methods
func _setup_ui_builder() -> void:
	var UiBuilderScript: Script = load("res://scripts/UiBuilder.gd")
	_ui_builder = UiBuilderScript.new()
	add_child(_ui_builder)
	_ui_controller = UiController.new()
	add_child(_ui_controller)
	_ui_builder.build(self, _ui_controller)
	_ui_controller.validate()
	_setup_campaign_controller()

func _setup_campaign_controller() -> void:
	var CampaignControllerScript: Script = load("res://scripts/CampaignController.gd")
	_campaign_controller = CampaignControllerScript.new()
	add_child(_campaign_controller)
	_campaign_controller.setup(self)
	_campaign_controller.level_started.connect(_on_campaign_level_started)
	_campaign_controller.level_retry_requested.connect(_on_level_retry)
	_campaign_controller.show_splash_requested.connect(_on_show_splash)
	_ui_builder.build_campaign_ui(self, _campaign_controller)

func _setup_economy() -> void:
	var EconomyScript: Script = load("res://scripts/Economy.gd")
	_economy = EconomyScript.new()
	add_child(_economy)
	_economy.set_costs(config)
	_economy.configure_resources(
		config.starting_wood,
		config.starting_food,
		config.starting_stone,
		config.starting_iron,
		config.base_resource_cap,
		config.unit_food_cost
	)

func _setup_units() -> void:
	var UnitCatalogScript: Script = load("res://scripts/UnitCatalog.gd")
	_unit_catalog = UnitCatalogScript.new()
	add_child(_unit_catalog)
	_unit_defs = _unit_catalog.build_defs(config)

	var UnitSpawnerScript: Script = load("res://scripts/UnitSpawner.gd")
	_unit_spawner = UnitSpawnerScript.new()
	add_child(_unit_spawner)
	_unit_spawner.setup(self, _world, _economy, _upgrade_manager, _performance_tracker)

	_build_spawn_buttons()
	_economy.set_unit_defs(_unit_defs)
	_economy.set_spawn_buttons(_spawn_buttons)
	_economy.update_buttons_for_base_level(_upgrade_manager.base_level, _upgrade_manager.archery_range_level, _upgrade_manager.barracks_level)
	_economy.set_base_upgrade_in_progress(_upgrade_manager.base_upgrade_in_progress)

func _setup_buildings() -> void:
	var BuildingCatalogScript: Script = load("res://scripts/BuildingCatalog.gd")
	_building_catalog = BuildingCatalogScript.new()
	add_child(_building_catalog)
	_building_defs = _building_catalog.build_defs(config)
	_build_build_categories()
	_build_build_buttons()
	_economy.set_build_defs(_building_defs)
	_economy.set_build_buttons(_build_buttons, _upgrade_button)
	if _build_category == "":
		_build_category = _default_build_category()
	_set_build_category(_build_category)
	_economy.update_buttons_for_base_level(_upgrade_manager.base_level, _upgrade_manager.archery_range_level, _upgrade_manager.barracks_level)

	var order: Array[String] = _building_catalog.get_order()
	if not order.is_empty():
		_set_build_mode(order[0])

func _setup_placement() -> void:
	var PlacementScript: Script = load("res://scripts/Placement.gd")
	_placement = PlacementScript.new()
	add_child(_placement)
	_placement.setup(self, _world, _economy, _upgrade_manager, _building_defs)

func _setup_resource_spawner() -> void:
	_resource_spawner = ResourceSpawner.new()
	add_child(_resource_spawner)
	_resource_spawner.setup(self, _world)

func _setup_path_generator() -> void:
	var PathGeneratorScript: Script = load("res://scripts/PathGenerator.gd")
	_path_generator = PathGeneratorScript.new()
	add_child(_path_generator)
	_path_generator.setup(_world, config)

func _setup_camera_controller() -> void:
	var CameraControllerScript: Script = load("res://scripts/CameraController.gd")
	_camera_controller = CameraControllerScript.new()
	add_child(_camera_controller)
	_camera_controller.setup(self, _world)

func _setup_game_state_manager() -> void:
	var GameStateManagerScript: Script = load("res://scripts/GameStateManager.gd")
	_game_state_manager = GameStateManagerScript.new()
	add_child(_game_state_manager)
	_game_state_manager.setup(self)

func _setup_upgrade_manager() -> void:
	var UpgradeManagerScript: Script = load("res://scripts/UpgradeManager.gd")
	_upgrade_manager = UpgradeManagerScript.new()
	add_child(_upgrade_manager)
	_upgrade_manager.setup(self, _world, _economy)

func _setup_map_editor() -> void:
	var MapEditorScript: Script = load("res://scripts/MapEditor.gd")
	_map_editor = MapEditorScript.new()
	add_child(_map_editor)
	_map_editor.setup(self, _world, _resource_spawner)

func _setup_performance_tracker() -> void:
	var PerformanceTrackerScript: Script = load("res://scripts/PerformanceTracker.gd")
	_performance_tracker = PerformanceTrackerScript.new()
	add_child(_performance_tracker)

func _setup_resource_catalog() -> void:
	var ResourceCatalogScript: Script = load("res://scripts/ResourceCatalog.gd")
	_resource_catalog = ResourceCatalogScript.new()
	add_child(_resource_catalog)
	var defs: Dictionary = _resource_catalog.build_defs(config)
	var order: Array[String] = _resource_catalog.get_order()
	for resource_id in defs.keys():
		if not order.has(resource_id):
			order.append(resource_id)
	_world.resources.initialize(defs, order)

# UI building methods
func _build_build_buttons() -> void:
	var build_buttons_box: HBoxContainer = null
	if _ui_controller != null:
		build_buttons_box = _ui_controller.build_buttons_box
	if build_buttons_box == null:
		return
	for child in build_buttons_box.get_children():
		child.queue_free()
	_build_buttons.clear()
	var order: Array[String] = _building_catalog.get_order()
	for building_id in order:
		if not _building_defs.has(building_id):
			continue
		var def: Dictionary = _building_defs[building_id]
		if _build_category != "" and str(def.get("category", "")) != _build_category:
			continue
		var button := Button.new()
		button.toggle_mode = true
		var label: String = str(def.get("label", building_id))
		var cost_label: String = _building_cost_label(def)
		button.text = label if cost_label == "" else "%s (%s)" % [label, cost_label]
		button.pressed.connect(Callable(self, "_set_build_mode").bind(building_id))
		build_buttons_box.add_child(button)
		_build_buttons[building_id] = button

func _build_build_categories() -> void:
	var build_category_box: HBoxContainer = null
	if _ui_controller != null:
		build_category_box = _ui_controller.build_category_box
	if build_category_box == null or _building_catalog == null:
		return
	for child in build_category_box.get_children():
		child.queue_free()
	_build_category_buttons.clear()
	var categories: Array[String] = _building_catalog.get_categories()
	for category in categories:
		var button := Button.new()
		button.text = category
		button.pressed.connect(Callable(self, "_set_build_category").bind(category))
		build_category_box.add_child(button)
		_build_category_buttons[category] = button

func _set_build_category(category: String) -> void:
	_build_category = category
	_build_build_buttons()
	if _economy != null:
		_economy.set_build_buttons(_build_buttons, _upgrade_button)
		_economy.set_build_category_filter("")
		_economy.update_buttons_for_base_level(_upgrade_manager.base_level, _upgrade_manager.archery_range_level, _upgrade_manager.barracks_level)
	if _build_category_buttons.has(category):
		_set_build_mode_for_category(category)

func _set_build_mode_for_category(category: String) -> void:
	for building_id in _building_defs.keys():
		var def: Dictionary = _building_defs[building_id]
		if str(def.get("category", "")) == category:
			_set_build_mode(building_id)
			return

func _default_build_category() -> String:
	if _building_catalog == null:
		return ""
	var categories: Array[String] = _building_catalog.get_categories()
	if categories.is_empty():
		return ""
	return categories[0]

func _building_cost_label(def: Dictionary) -> String:
	var parts: Array[String] = []
	var costs: Dictionary = def.get("costs", {})
	var food_cost: int = costs.get("food", 0)
	var wood_cost: int = costs.get("wood", 0)
	var stone_cost: int = costs.get("stone", 0)
	var iron_cost: int = costs.get("iron", 0)
	if food_cost > 0:
		parts.append("%dF" % food_cost)
	if wood_cost > 0:
		parts.append("%dW" % wood_cost)
	if stone_cost > 0:
		parts.append("%dS" % stone_cost)
	if iron_cost > 0:
		parts.append("%dI" % iron_cost)
	return "+".join(parts)

func _build_spawn_buttons() -> void:
	var spawn_units_box: VBoxContainer = null
	if _ui_controller != null:
		spawn_units_box = _ui_controller.spawn_units_box
	if spawn_units_box == null:
		return
	for child in spawn_units_box.get_children():
		child.queue_free()
	_spawn_buttons.clear()
	var order: Array[String] = _unit_catalog.get_order()
	for unit_id in order:
		if not _unit_defs.has(unit_id):
			continue
		var def: Dictionary = _unit_defs[unit_id]
		var button_row := HBoxContainer.new()
		button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_row.add_theme_constant_override("separation", 6)
		var button := Button.new()
		var label: String = str(def.get("label", unit_id))
		var cost_label: String = _unit_cost_label(def)
		button.text = label if cost_label == "" else "%s (%s)" % [label, cost_label]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_stretch_ratio = 2.0
		button.pressed.connect(Callable(self, "_spawn_unit_by_id").bind(unit_id))
		button_row.add_child(button)
		var button_ten := Button.new()
		button_ten.text = "+10"
		button_ten.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_ten.size_flags_stretch_ratio = 1.0
		button_ten.pressed.connect(Callable(self, "_spawn_units_by_id").bind(unit_id, 10))
		button_row.add_child(button_ten)
		var button_twenty_five := Button.new()
		button_twenty_five.text = "+25"
		button_twenty_five.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button_twenty_five.size_flags_stretch_ratio = 1.0
		button_twenty_five.pressed.connect(Callable(self, "_spawn_units_by_id").bind(unit_id, 25))
		button_row.add_child(button_twenty_five)
		spawn_units_box.add_child(button_row)
		_spawn_buttons[unit_id] = {
			1: button,
			10: button_ten,
			25: button_twenty_five
		}

func _unit_cost_label(def: Dictionary) -> String:
	var parts: Array[String] = []
	var food_cost: int = def.get("food_cost", 0)
	var wood_cost: int = def.get("wood_cost", 0)
	var stone_cost: int = def.get("stone_cost", 0)
	var iron_cost: int = def.get("iron_cost", 0)
	if food_cost > 0:
		parts.append("%dF" % food_cost)
	if wood_cost > 0:
		parts.append("%dW" % wood_cost)
	if stone_cost > 0:
		parts.append("%dS" % stone_cost)
	if iron_cost > 0:
		parts.append("%dI" % iron_cost)
	return "+".join(parts)

func _spawn_unit_by_id(unit_id: String) -> void:
	_spawn_units_by_id(unit_id, 1)

func _spawn_units_by_id(unit_id: String, count: int) -> void:
	if count <= 0:
		return
	if not _unit_defs.has(unit_id):
		return
	var def: Dictionary = _unit_defs[unit_id]
	if _unit_spawner == null:
		return
	if _economy == null or not _economy.can_spawn_unit_def_count(def, count):
		return
	for i in range(count):
		_unit_spawner.spawn_unit(unit_id, def)

# Game state methods
func _reset_game() -> void:
	_clear_constructions()
	_clear_buildings()
	_clear_enemy_towers()
	_generate_random_path()
	_rebuild_path()
	if _resource_spawner != null:
		_resource_spawner.spawn_resources()
	_clear_units()
	_reset_bases()
	_reset_fog()
	_upgrade_manager.base_upgrade_in_progress = false
	_game_state_manager.reset()
	_economy.update_buttons_for_base_level(_upgrade_manager.base_level, _upgrade_manager.archery_range_level, _upgrade_manager.barracks_level)
	_economy.set_base_upgrade_in_progress(false)
	_enemy_timer.start()

	if _performance_tracker != null:
		_performance_tracker.start_tracking()

	queue_redraw()

func _reset_for_play() -> void:
	_clear_units()
	_clear_constructions()
	_clear_buildings()
	_reset_bases()
	_reset_fog()
	_upgrade_manager.base_upgrade_in_progress = false
	_game_state_manager.reset()
	_upgrade_manager.set_upgrade_modal_visible(false)

	var start_wood: int = config.starting_wood
	var start_food: int = config.starting_food
	var start_stone: int = config.starting_stone
	var start_iron: int = config.starting_iron
	var spawn_rate: float = config.spawn_interval

	if CampaignManager.is_campaign_mode and CampaignManager.current_level_id != "":
		var resources := CampaignManager.get_starting_resources(CampaignManager.current_level_id, CampaignManager.current_difficulty)
		start_wood = int(resources.get("wood", config.starting_wood))
		start_food = int(resources.get("food", config.starting_food))
		start_stone = int(resources.get("stone", config.starting_stone))
		start_iron = int(resources.get("iron", config.starting_iron))
		spawn_rate = CampaignManager.get_spawn_interval(CampaignManager.current_level_id, CampaignManager.current_difficulty)

	if _economy != null:
		_economy.configure_resources(start_wood, start_food, start_stone, start_iron, config.base_resource_cap, config.unit_food_cost)
		_economy.update_buttons_for_base_level(_upgrade_manager.base_level, _upgrade_manager.archery_range_level, _upgrade_manager.barracks_level)
		_economy.set_base_upgrade_in_progress(false)

	if _enemy_timer != null:
		_enemy_timer.wait_time = spawn_rate
		_enemy_timer.start()

	if _performance_tracker != null:
		_performance_tracker.start_tracking()

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

func _clear_units() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("allies"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("projectiles"):
		node.queue_free()
	_economy.reset_units()

func _reset_bases() -> void:
	_world.bases.reset_hp()

func _update_base_label() -> void:
	_update_upgrade_button_text()
	_economy.update_buttons_for_base_level(_upgrade_manager.base_level, _upgrade_manager.archery_range_level, _upgrade_manager.barracks_level)
	_economy.set_base_upgrade_in_progress(_upgrade_manager.base_upgrade_in_progress)
	_upgrade_manager.update_base_upgrade_indicator()
	_economy.set_archery_level(_upgrade_manager.archery_range_level)

func _upgrade_button_text() -> String:
	if _upgrade_manager.base_level >= 2:
		return "Upgrade Base (%d Wood + %d Stone)" % [config.base_upgrade_cost, config.base_upgrade_stone_cost]
	return "Upgrade Base (%d Wood)" % config.base_upgrade_cost

func _update_upgrade_button_text() -> void:
	if _upgrade_button != null:
		_upgrade_button.text = _upgrade_button_text()

func _set_build_mode(mode: String) -> void:
	_build_mode = mode
	if _ui_controller != null:
		if _building_defs.has(mode):
			var def: Dictionary = _building_defs[mode]
			var label: String = str(def.get("label", mode))
			_ui_controller.set_build_label_text("Build: %s" % label)
		else:
			_ui_controller.set_build_label_text("Build: ")
	for key in _build_buttons.keys():
		var button := _build_buttons[key] as Button
		if button == null:
			continue
		button.button_pressed = key == mode
		if mode == "":
			button.release_focus()

func _on_upgrade_base_pressed() -> void:
	_upgrade_manager.show_upgrade_modal("base", _world.bases.end)

# Path methods
func _generate_random_path() -> void:
	if _path_generator == null:
		return
	var result: Dictionary = _path_generator.generate_random_path()
	_world.path.cells = result.get("path", [])
	_world.path.base_start_cell = result.get("start", Vector2i(-1, -1))
	_world.path.base_end_cell = result.get("end", Vector2i(-1, -1))

func _add_path_cell(world_pos: Vector2) -> void:
	var grid := _world.grid
	var cell := Vector2i(int(world_pos.x / grid.cell_size), int(world_pos.y / grid.cell_size))
	if not grid.is_in_bounds(cell):
		return
	if _world.occupancy.occupied.has(cell):
		return
	if _world.resources.has_any_at(cell):
		return
	if _world.occupancy.building_by_cell.has(cell):
		return
	if _world.path.is_path_cell(cell):
		return
	_world.path.cells.append(cell)
	_rebuild_path()
	queue_redraw()

func _remove_path_cell(world_pos: Vector2) -> void:
	var grid := _world.grid
	var cell := Vector2i(int(world_pos.x / grid.cell_size), int(world_pos.y / grid.cell_size))
	if not grid.is_in_bounds(cell):
		return
	if not _world.path.is_path_cell(cell):
		return
	_world.path.cells.erase(cell)
	_rebuild_path()
	queue_redraw()

func _rebuild_path() -> void:
	var path := _world.path
	var grid := _world.grid
	path.ordered_cells = []
	path.valid = false
	if path.cells.is_empty():
		_world.bases.clear()
		return

	var walkable: Dictionary[Vector2i, bool] = {}
	for cell in path.cells:
		walkable[cell] = true

	var starts: Array[Vector2i] = []
	if path.base_start_cell != Vector2i(-1, -1) and path.base_end_cell != Vector2i(-1, -1):
		if walkable.has(path.base_start_cell) and walkable.has(path.base_end_cell):
			starts.append(path.base_start_cell)
	else:
		for cell in path.cells:
			if cell.x == grid.path_margin and grid.is_in_base_band(cell):
				starts.append(cell)
	if starts.is_empty():
		_world.bases.clear()
		return

	var frontier: Array[Vector2i] = starts.duplicate()
	var came_from: Dictionary[Vector2i, Vector2i] = {}
	for start in starts:
		came_from[start] = Vector2i(-999, -999)

	var goal := Vector2i(-1, -1)
	if path.base_start_cell != Vector2i(-1, -1) and path.base_end_cell != Vector2i(-1, -1):
		goal = path.base_end_cell
	var directions: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front() as Vector2i
		if goal != Vector2i(-1, -1):
			if current == goal:
				break
		elif current.x == grid.grid_width - 1 - grid.path_margin and grid.is_in_base_band(current):
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
		_world.bases.clear()
		return
	if not came_from.has(goal):
		path.valid = false
		_world.bases.clear()
		return

	var path_rev: Array[Vector2i] = []
	var step: Vector2i = goal
	while step != Vector2i(-999, -999):
		path_rev.append(step)
		if not came_from.has(step):
			path.valid = false
			_world.bases.clear()
			return
		step = came_from[step]

	path_rev.reverse()
	path.ordered_cells = path_rev
	path.valid = true
	_update_bases()

func _update_bases() -> void:
	var path := _world.path
	var grid := _world.grid
	if not path.valid or path.ordered_cells.is_empty():
		_world.bases.clear()
		return

	var start_cell := path.ordered_cells[0]
	var end_cell := path.ordered_cells[path.ordered_cells.size() - 1]

	if _world.bases.start == null:
		_world.bases.start = preload("res://scenes/Base.tscn").instantiate() as Base
		add_child(_world.bases.start)
	var enemy_base_hp := 500
	if CampaignManager.is_campaign_mode and CampaignManager.current_level_id != "":
		var multiplier := CampaignManager.get_enemy_base_hp_multiplier(CampaignManager.current_level_id, CampaignManager.current_difficulty)
		enemy_base_hp = int(500.0 * multiplier)
	_world.bases.start.max_hp = enemy_base_hp
	_world.bases.start.reset_hp()
	_world.bases.start.size = grid.cell_size * 3
	_world.bases.start.position = grid.cell_to_world(start_cell)
	if not _world.bases.start.died.is_connected(_on_base_died):
		_world.bases.start.died.connect(_on_base_died.bind(false))

	if _world.bases.end == null:
		_world.bases.end = preload("res://scenes/Base.tscn").instantiate() as Base
		add_child(_world.bases.end)
	_world.bases.end.size = grid.cell_size * 3
	_world.bases.end.position = grid.cell_to_world(end_cell)
	_world.bases.end.is_goal = true
	if not _world.bases.end.died.is_connected(_on_base_died):
		_world.bases.end.died.connect(_on_base_died.bind(true))

# Enemy spawning
func _setup_enemy_timer() -> void:
	_enemy_timer = Timer.new()
	_enemy_timer.wait_time = config.spawn_interval
	_enemy_timer.autostart = true
	_enemy_timer.timeout.connect(_spawn_enemy)
	add_child(_enemy_timer)
	_update_enemy_spawn_rate()

func _update_enemy_spawn_rate() -> void:
	if _enemy_timer == null:
		return
	var multiplier: float = 2.0 if _upgrade_manager.base_level >= 2 else 1.0
	_enemy_timer.wait_time = config.spawn_interval / multiplier

func _spawn_enemy() -> void:
	if _game_state_manager.is_splash_active():
		return
	if _game_state_manager.is_game_over():
		return
	if not _world.path.valid:
		return
	var enemy: Node2D = preload("res://scenes/Enemy.tscn").instantiate() as Node2D
	enemy.visible = false
	enemy.path_points = _world.path.get_path_points(_world.grid)
	if CampaignManager.is_campaign_mode and CampaignManager.current_level_id != "":
		enemy.hp_multiplier = CampaignManager.get_enemy_hp_multiplier(CampaignManager.current_level_id, CampaignManager.current_difficulty)
		enemy.damage_multiplier = CampaignManager.get_enemy_damage_multiplier(CampaignManager.current_level_id, CampaignManager.current_difficulty)
	enemy.reached_goal.connect(_on_enemy_reached_goal.bind(enemy))
	enemy.died.connect(_on_enemy_died)
	add_child(enemy)

func _on_enemy_died() -> void:
	if _performance_tracker != null and _performance_tracker.is_tracking():
		_performance_tracker.record_enemy_killed()

func _on_enemy_reached_goal(enemy: Node2D) -> void:
	if _world.bases.end != null:
		_world.bases.end.take_damage(1)
	if enemy != null and is_instance_valid(enemy):
		enemy.queue_free()

func _on_unit_reached_goal(unit: Node2D) -> void:
	if _world.bases.start != null:
		_world.bases.start.take_damage(1)
	_on_unit_removed(unit, "")

func _on_unit_removed(unit: Node2D, unit_id: String = "") -> void:
	if unit != null and is_instance_valid(unit):
		unit.queue_free()
	_economy.on_unit_removed()
	if _performance_tracker != null and _performance_tracker.is_tracking():
		_performance_tracker.record_unit_lost(unit_id)

func _on_base_died(is_player_base: bool) -> void:
	_game_state_manager.on_game_over(is_player_base)
	_handle_level_end(is_player_base)

func _handle_level_end(is_player_base: bool) -> void:
	if _performance_tracker != null and _performance_tracker.has_method("stop_tracking"):
		_performance_tracker.stop_tracking()

	if not CampaignManager.is_campaign_mode:
		return

	if _ui_controller != null:
		_ui_controller.set_game_over_visible(false)

	var victory: bool = not is_player_base
	var base_hp: int = 0
	var base_max_hp: int = 25
	if _world.bases.end != null:
		base_hp = _world.bases.end.hp
		base_max_hp = _world.bases.end.max_hp

	var result: RefCounted = _performance_tracker.build_result(
		CampaignManager.current_level_id,
		CampaignManager.current_difficulty,
		victory,
		base_hp,
		base_max_hp
	)

	_campaign_controller.show_level_complete(result)

# UI callbacks
func _on_restart_pressed() -> void:
	get_tree().reload_current_scene.call_deferred()

func _on_play_pressed() -> void:
	_on_sandbox_pressed()

func _on_sandbox_pressed() -> void:
	CampaignManager.exit_campaign()
	_game_state_manager.set_splash_active(false)
	_set_editor_active(false)
	_upgrade_manager.set_upgrade_modal_visible(false)
	var map_name: String = _map_editor.get_selected_map_name()
	if map_name != "":
		var MapIOScript: Script = load("res://scripts/MapIO.gd")
		var data: Dictionary = MapIOScript.call("load_map", map_name)
		if not data.is_empty() and _map_editor.apply_map_data(data):
			_map_editor.map_data = data
			_map_editor.use_custom_map = true
			_reset_for_play()
			return
	if _map_editor.use_custom_map and not _map_editor.map_data.is_empty():
		_map_editor.apply_map_data(_map_editor.map_data)
		_reset_for_play()
	else:
		_reset_game()

func _on_campaign_pressed() -> void:
	_campaign_controller.show_campaign_select()

func _on_campaign_level_started(level_id: String, difficulty: String, map_data: Dictionary) -> void:
	_game_state_manager.set_splash_active(false)
	_set_editor_active(false)
	_upgrade_manager.set_upgrade_modal_visible(false)

	if not map_data.is_empty() and not map_data.get("auto_generate", true):
		if _map_editor.apply_map_data(map_data):
			_map_editor.map_data = map_data
			_map_editor.use_custom_map = true
			_reset_for_play()
			return

	_map_editor.use_custom_map = false
	_reset_game()

func _on_level_retry() -> void:
	if _ui_controller != null:
		_ui_controller.set_game_over_visible(false)
	_reset_for_play()

func _on_show_splash() -> void:
	_game_state_manager.set_splash_active(true)

func _on_resume_pressed() -> void:
	_game_state_manager.set_paused(false)

func _on_menu_pressed() -> void:
	_game_state_manager.set_paused(not _game_state_manager.is_paused())

func _on_speed_pressed() -> void:
	_game_state_manager.set_fast_forward(not _game_state_manager.is_fast_forward())

func _on_upgrade_modal_pressed() -> void:
	var modal_type: String = _upgrade_manager.get_upgrade_modal_type()
	if modal_type == "base":
		_upgrade_manager.try_upgrade_base()
	elif modal_type == "archery_range":
		var range_target: Node2D = _upgrade_manager.get_upgrade_modal_target()
		if range_target != null and is_instance_valid(range_target):
			_upgrade_manager.try_upgrade_archery_range(range_target)
	_upgrade_manager.update_upgrade_modal()

func _on_upgrade_modal_close_pressed() -> void:
	_upgrade_manager.set_upgrade_modal_visible(false)

func _on_create_map_pressed() -> void:
	_game_state_manager.set_splash_active(false)
	_set_editor_active(true)
	_map_editor.start_new_map()

func _on_editor_tool_pressed(tool: String) -> void:
	_map_editor.set_tool(tool)

func _on_editor_save_pressed() -> void:
	_map_editor.save_map()

func _on_editor_load_pressed() -> void:
	_map_editor.load_map()

func _on_editor_export_campaign_pressed() -> void:
	_map_editor.export_campaign()

func _on_editor_back_pressed() -> void:
	_map_editor.exit_to_menu()

func _on_exit_pressed() -> void:
	get_tree().quit()

func _set_editor_active(active: bool) -> void:
	_editor_active = active
	_map_editor.set_active(active)

# Helper methods
func _is_over_player_base(world_pos: Vector2) -> bool:
	if _world.bases.end == null:
		return false
	var half: float = _world.bases.end.size * 0.5
	var local: Vector2 = world_pos - _world.bases.end.position
	return absf(local.x) <= half and absf(local.y) <= half

func _get_archery_range_at(world_pos: Vector2) -> Node2D:
	return _upgrade_manager.get_archery_range_at(world_pos)

func _update_archery_range_indicators() -> void:
	_upgrade_manager.update_archery_range_indicators()

func _update_base_upgrade_indicator() -> void:
	_upgrade_manager.update_base_upgrade_indicator()

func _update_stats_panel() -> void:
	var base_level: int = 0
	if _upgrade_manager != null:
		base_level = _upgrade_manager.base_level
	if _ui_controller != null:
		_ui_controller.update_stats(_performance_tracker, base_level, _world.bases.end)

func _register_archery_range(range: Node2D) -> void:
	_upgrade_manager.register_archery_range(range)

func _register_barracks(barracks: Node2D) -> void:
	_upgrade_manager.register_barracks(barracks)

func _spawn_construction(top_left: Vector2i, size: int, duration: float) -> Node2D:
	var grid := _world.grid
	var ConstructionScript: Script = load("res://scripts/Construction.gd")
	var construction: Node2D = ConstructionScript.new()
	construction.cell_size = grid.cell_size
	construction.size_cells = size
	construction.duration = duration
	construction.position = Vector2(top_left.x * grid.cell_size, top_left.y * grid.cell_size)
	add_child(construction)
	return construction

# Enemy tower methods
func _place_enemy_tower(cell: Vector2i) -> void:
	var grid := _world.grid
	var script: Script = load("res://scripts/EnemyTower.gd")
	var tower: Node2D = script.new() as Node2D
	tower.set("cell", cell)
	tower.set("cell_size", grid.cell_size)
	add_child(tower)
	_world.occupancy.enemy_towers.append(tower)
	_world.occupancy.enemy_tower_by_cell[cell] = tower

func _remove_enemy_tower_at(cell: Vector2i) -> bool:
	if not _world.occupancy.enemy_tower_by_cell.has(cell):
		return false
	var tower: Node2D = _world.occupancy.enemy_tower_by_cell[cell] as Node2D
	_world.occupancy.enemy_tower_by_cell.erase(cell)
	if tower != null and is_instance_valid(tower):
		_world.occupancy.enemy_towers.erase(tower)
		tower.queue_free()
	return true

func _clear_enemy_towers() -> void:
	for tower in _world.occupancy.enemy_towers:
		if tower != null and is_instance_valid(tower):
			tower.queue_free()
	_world.occupancy.enemy_towers.clear()
	_world.occupancy.enemy_tower_by_cell.clear()

func _clear_constructions() -> void:
	for node in get_tree().get_nodes_in_group("construction"):
		node.queue_free()

func _clear_buildings() -> void:
	var unique: Dictionary = {}
	for building in _world.occupancy.building_by_cell.values():
		if building == null or not is_instance_valid(building):
			continue
		if unique.has(building):
			continue
		unique[building] = true
		building.queue_free()
	_world.occupancy.building_by_cell.clear()
	_world.occupancy.occupied.clear()
	_clear_grunt_towers()
	_upgrade_manager.reset()

func _clear_grunt_towers() -> void:
	for node in get_tree().get_nodes_in_group("grunt_towers"):
		if node != null and is_instance_valid(node):
			node.queue_free()

# Fog of War
func _reset_fog() -> void:
	_world.fog.reset(_world.grid)

func _update_fog_progression() -> void:
	if not _world.fog.enabled:
		return

	for unit in get_tree().get_nodes_in_group("allies"):
		var column: int = int(unit.position.x / _world.grid.cell_size)
		column = clampi(column, 0, _world.grid.grid_width - 1)

		if column < _world.fog.revealed_column:
			_world.fog.revealed_column = column
			queue_redraw()

	_update_fog_visibility()

func _update_fog_visibility() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var column: int = int(enemy.position.x / _world.grid.cell_size)
		enemy.visible = column >= _world.fog.revealed_column

	if _world.bases.start != null:
		var base_column: int = int(_world.bases.start.position.x / _world.grid.cell_size)
		_world.bases.start.visible = base_column >= _world.fog.revealed_column

	for tower in _world.occupancy.enemy_towers:
		if tower != null and is_instance_valid(tower):
			var column: int = int(tower.position.x / _world.grid.cell_size)
			tower.visible = column >= _world.fog.revealed_column

# Drawing
func _draw() -> void:
	_draw_path()
	_draw_player_zone()
	if _editor_active:
		_map_editor.draw(self)
	_draw_grid()
	if _placement != null:
		_placement.draw_hover(self, _build_mode)
	_draw_fog_of_war()

func _draw_grid() -> void:
	var grid := _world.grid
	var grid_color := Color(0.2, 0.2, 0.2)
	var zoom := 1.0
	if _camera_controller != null:
		zoom = _camera_controller.get_zoom()
	var line_width := maxf(1.0, 1.0 / zoom)
	for x in range(grid.grid_width + 1):
		var from := Vector2(x * grid.cell_size, 0)
		var to := Vector2(x * grid.cell_size, grid.grid_height * grid.cell_size)
		draw_line(from, to, grid_color, line_width)
	for y in range(grid.grid_height + 1):
		var from := Vector2(0, y * grid.cell_size)
		var to := Vector2(grid.grid_width * grid.cell_size, y * grid.cell_size)
		draw_line(from, to, grid_color, line_width)

func _draw_player_zone() -> void:
	var grid := _world.grid
	var start_x: int = max(grid.grid_width - grid.player_zone_width, 0)
	var zone_color: Color = Color(0.2, 0.6, 0.25, 0.18)
	for x in range(start_x, grid.grid_width):
		for y in range(grid.grid_height):
			var rect := Rect2(x * grid.cell_size, y * grid.cell_size, grid.cell_size, grid.cell_size)
			draw_rect(rect, zone_color, true)

func _draw_path() -> void:
	var grid := _world.grid
	var path := _world.path
	var painted_color := Color(0.9, 0.7, 0.2, 0.25)
	for cell in path.cells:
		if _world.fog.enabled and not _editor_active and cell.x < _world.fog.revealed_column:
			continue
		var rect := Rect2(cell.x * grid.cell_size, cell.y * grid.cell_size, grid.cell_size, grid.cell_size)
		draw_rect(rect, painted_color, true)

	var ordered_color := Color(0.9, 0.7, 0.2, 0.6) if path.valid else Color(0.9, 0.2, 0.2, 0.6)
	for cell in path.ordered_cells:
		if _world.fog.enabled and not _editor_active and cell.x < _world.fog.revealed_column:
			continue
		var rect := Rect2(cell.x * grid.cell_size, cell.y * grid.cell_size, grid.cell_size, grid.cell_size)
		draw_rect(rect, ordered_color, true)

func _draw_fog_of_war() -> void:
	if not _world.fog.enabled or _editor_active:
		return

	var grid := _world.grid
	for x in range(0, _world.fog.revealed_column):
		for y in range(grid.grid_height):
			var rect := Rect2(x * grid.cell_size, y * grid.cell_size, grid.cell_size, grid.cell_size)
			draw_rect(rect, _world.fog.color, true)

	if _world.fog.revealed_column > 0:
		var edge_color := Color(_world.fog.color.r, _world.fog.color.g, _world.fog.color.b, 0.4)
		for y in range(grid.grid_height):
			var rect := Rect2((_world.fog.revealed_column - 1) * grid.cell_size, y * grid.cell_size, grid.cell_size, grid.cell_size)
			draw_rect(rect, edge_color, true)

# Compatibility accessors (for backward compatibility with external scripts)
var path_cells: Array[Vector2i]:
	get:
		return _world.path.cells
	set(value):
		_world.path.cells = value

func _is_in_bounds(cell: Vector2i) -> bool:
	return _world.grid.is_in_bounds(cell)

func set_path_cells(cells: Array[Vector2i]) -> void:
	_world.path.cells = cells
	_rebuild_path()
	queue_redraw()
