class_name MapEditor
extends Node

const GameWorld = preload("res://scripts/state/GameWorld.gd")

signal editor_activated()
signal editor_deactivated()
signal map_loaded(data: Dictionary)

var _main: Node
var _world: GameWorld
var _resource_spawner: Node

var active := false
var tool := "path"
var dragging := false
var last_cell := Vector2i(-1, -1)
var use_custom_map := false
var map_data: Dictionary = {}
var map_list: Array[String] = []

var _editor_panel: PanelContainer
var _editor_name_input: LineEdit
var _editor_campaign_select: OptionButton
var _editor_status_label: Label
var _editor_tool_label: Label

func setup(main_node: Node, world: GameWorld, resource_spawner_node: Node) -> void:
	_main = main_node
	_world = world
	_resource_spawner = resource_spawner_node
	_sync_ui_refs()

func _sync_ui_refs() -> void:
	if _main == null or _main._ui_controller == null:
		return
	_editor_panel = _main._ui_controller.editor_panel
	_editor_name_input = _main._ui_controller.editor_name_input
	_editor_campaign_select = _main._ui_controller.editor_campaign_select
	_editor_status_label = _main._ui_controller.editor_status_label
	_editor_tool_label = _main._ui_controller.editor_tool_label

func is_active() -> bool:
	return active

func set_active(is_active: bool) -> void:
	active = is_active
	if _editor_panel != null:
		_editor_panel.visible = active
	if _main._ui_controller != null:
		_main._ui_controller.set_hud_visible(not active)
		_main._ui_controller.set_game_over_visible(false)
	if _main._enemy_timer != null:
		if active:
			_main._enemy_timer.stop()
		else:
			_main._enemy_timer.start()
	if active:
		_main._game_state_manager.set_paused(false)
		_main._game_state_manager.set_fast_forward(false)
		refresh_campaign_level_list()
		_main._clear_units()
		_main._clear_constructions()
		_clear_buildings()
		_clear_enemy_towers()
		if _resource_spawner != null:
			_resource_spawner.clear_resources()
		_world.bases.clear()
		_main.queue_redraw()
		editor_activated.emit()
	else:
		editor_deactivated.emit()

func set_tool(new_tool: String) -> void:
	tool = new_tool
	update_tool_label()

func update_tool_label() -> void:
	if _editor_tool_label != null:
		var name := tool.capitalize()
		if tool == "base_start":
			name = "Player Base"
		elif tool == "base_end":
			name = "Enemy Base"
		elif _is_resource_tool(tool):
			var def: Dictionary = _world.resources.defs.get(tool, {})
			name = str(def.get("label", tool))
		_editor_tool_label.text = "Tool: %s" % name

func set_status(text: String) -> void:
	if _editor_status_label != null:
		_editor_status_label.text = text

func refresh_map_list(select_name: String = "") -> void:
	var MapIOScript: Script = load("res://scripts/MapIO.gd")
	var names: Array = MapIOScript.call("list_maps")
	map_list.clear()
	if names != null:
		for entry in names:
			if entry is String:
				map_list.append(entry)
	var map_select: OptionButton = null
	if _main._ui_controller != null:
		map_select = _main._ui_controller.splash_map_select
	if map_select == null:
		return
	map_select.clear()
	map_select.add_item("Random")
	for name in map_list:
		map_select.add_item(name)
	if select_name != "" and map_list.has(select_name):
		var index := map_list.find(select_name)
		map_select.select(index + 1)
	else:
		map_select.select(0)

func get_selected_map_name() -> String:
	var map_select: OptionButton = null
	if _main._ui_controller != null:
		map_select = _main._ui_controller.splash_map_select
	if map_select == null:
		return ""
	var idx: int = map_select.get_selected_id()
	if idx <= 0:
		return ""
	var index: int = idx - 1
	if index >= 0 and index < map_list.size():
		return map_list[index]
	return ""

func handle_input(event: InputEvent) -> bool:
	if not active:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragging = true
			last_cell = Vector2i(-1, -1)
			handle_click(_main.get_global_mouse_position())
		else:
			dragging = false
		return true
	elif event is InputEventMouseMotion and dragging:
		handle_drag(_main.get_global_mouse_position())
		return true
	return false

func handle_click(world_pos: Vector2) -> void:
	var grid := _world.grid
	var cell := Vector2i(int(world_pos.x / grid.cell_size), int(world_pos.y / grid.cell_size))
	if not grid.is_in_bounds(cell):
		return
	if tool == "path":
		if _world.resources.has_any_at(cell):
			return
		if not _world.path.cells.has(cell):
			_world.path.cells.append(cell)
		_main._rebuild_path()
		_main.queue_redraw()
		return
	if tool == "erase":
		if _resource_spawner != null:
			if _resource_spawner.remove_resource_at(cell):
				_main.queue_redraw()
				return
		if _remove_enemy_tower_at(cell):
			_main.queue_redraw()
			return
		if _world.path.cells.has(cell):
			_world.path.cells.erase(cell)
			_main._rebuild_path()
			_main.queue_redraw()
			return
		if _world.path.base_start_cell != Vector2i(-1, -1) and _is_in_base_area(_world.path.base_start_cell, cell):
			_world.path.base_start_cell = Vector2i(-1, -1)
		if _world.path.base_end_cell != Vector2i(-1, -1) and _is_in_base_area(_world.path.base_end_cell, cell):
			_world.path.base_end_cell = Vector2i(-1, -1)
		if _world.path.base_start_cell == Vector2i(-1, -1) or _world.path.base_end_cell == Vector2i(-1, -1):
			_main._rebuild_path()
			_main.queue_redraw()
		return
	if tool == "base_start" or tool == "base_end":
		if not _can_place_base(cell, tool):
			return
		if tool == "base_start":
			_world.path.base_end_cell = cell
		else:
			_world.path.base_start_cell = cell
		if not _world.path.cells.has(cell):
			_world.path.cells.append(cell)
		_main._rebuild_path()
		_main.queue_redraw()
		return
	if tool == "enemy_tower":
		if not _can_place_enemy_tower(cell):
			return
		_place_enemy_tower(cell)
		_main.queue_redraw()
		return
	if _is_resource_tool(tool):
		if _resource_spawner == null:
			return
		var placed: bool = _resource_spawner.place_resource(tool, cell)
		if placed:
			_main.queue_redraw()
		return

func handle_drag(world_pos: Vector2) -> void:
	if tool != "path" and tool != "erase":
		return
	var grid := _world.grid
	var cell := Vector2i(int(world_pos.x / grid.cell_size), int(world_pos.y / grid.cell_size))
	if cell == last_cell:
		return
	last_cell = cell
	handle_click(world_pos)

func _can_place_base(center: Vector2i, kind: String) -> bool:
	var grid := _world.grid
	var path := _world.path
	if kind == "base_start" and not grid.is_in_player_zone(center):
		return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not grid.is_in_bounds(cell):
				return false
			if _world.resources.has_any_at(cell):
				return false
			if path.cells.has(cell) and cell != center:
				return false
			if path.base_start_cell != Vector2i(-1, -1) and _is_in_base_area(path.base_start_cell, cell):
				return false
			if path.base_end_cell != Vector2i(-1, -1) and _is_in_base_area(path.base_end_cell, cell):
				return false
	return true

func _is_in_base_area(center: Vector2i, cell: Vector2i) -> bool:
	return abs(center.x - cell.x) <= 1 and abs(center.y - cell.y) <= 1

func _can_place_enemy_tower(cell: Vector2i) -> bool:
	var grid := _world.grid
	var path := _world.path
	var bases := _world.bases
	if not grid.is_in_bounds(cell):
		return false
	if bases.is_base_cell(cell, path, grid):
		return false
	if path.cells.has(cell):
		return false
	if _world.resources.has_any_at(cell):
		return false
	if _world.occupancy.enemy_tower_by_cell.has(cell):
		return false
	return true

func _is_resource_tool(t: String) -> bool:
	return _world.resources.defs.has(t)

func draw(drawer: Node2D) -> void:
	if not active:
		return
	_draw_band(drawer)
	_draw_bases(drawer)
	_draw_hover(drawer)

func _draw_band(drawer: Node2D) -> void:
	var grid := _world.grid
	var band: Vector2i = grid.base_band_bounds()
	var color: Color = Color(0.2, 0.4, 0.8, 0.12)
	for y in range(band.x, band.y + 1):
		for x in range(grid.grid_width):
			var rect := Rect2(x * grid.cell_size, y * grid.cell_size, grid.cell_size, grid.cell_size)
			drawer.draw_rect(rect, color, true)

func _draw_bases(drawer: Node2D) -> void:
	var path := _world.path
	if path.base_end_cell != Vector2i(-1, -1):
		_draw_base(drawer, path.base_end_cell, Color(0.2, 0.6, 1.0, 0.5))
	if path.base_start_cell != Vector2i(-1, -1):
		_draw_base(drawer, path.base_start_cell, Color(0.9, 0.2, 0.2, 0.5))

func _draw_base(drawer: Node2D, center: Vector2i, color: Color) -> void:
	var grid := _world.grid
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not grid.is_in_bounds(cell):
				continue
			var rect := Rect2(cell.x * grid.cell_size, cell.y * grid.cell_size, grid.cell_size, grid.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _draw_hover(drawer: Node2D) -> void:
	var grid := _world.grid
	var path := _world.path
	var bases := _world.bases
	if tool == "base_start" or tool == "base_end":
		var cell := _mouse_cell()
		if not grid.is_in_bounds(cell):
			return
		var valid: bool = _can_place_base(cell, tool)
		_draw_square(drawer, cell, 3, valid)
	elif tool == "path":
		var cell := _mouse_cell()
		if not grid.is_in_bounds(cell):
			return
		if _world.resources.has_any_at(cell):
			return
		_draw_square(drawer, cell, 1, true)
	elif _is_resource_tool(tool):
		var cell := _mouse_cell()
		if not grid.is_in_bounds(cell):
			return
		var valid: bool = true
		if _world.resources.has_any_at(cell):
			valid = false
		if path.cells.has(cell) or bases.is_base_cell(cell, path, grid):
			valid = false
		_draw_square_top_left(drawer, cell, 2, valid)
	elif tool == "enemy_tower":
		var cell := _mouse_cell()
		if not grid.is_in_bounds(cell):
			return
		var valid: bool = _can_place_enemy_tower(cell)
		_draw_square(drawer, cell, 1, valid)
	elif tool == "erase":
		var cell := _mouse_cell()
		if not grid.is_in_bounds(cell):
			return
		var valid: bool = _world.resources.has_any_at(cell) or path.cells.has(cell) or bases.is_base_cell(cell, path, grid) or _world.occupancy.enemy_tower_by_cell.has(cell)
		_draw_square(drawer, cell, 1, valid)

func _mouse_cell() -> Vector2i:
	var grid := _world.grid
	var world_pos: Vector2 = _main.get_global_mouse_position()
	return Vector2i(int(world_pos.x / grid.cell_size), int(world_pos.y / grid.cell_size))

func _draw_square(drawer: Node2D, center: Vector2i, size_cells: int, valid: bool) -> void:
	var grid := _world.grid
	var color := Color(0.2, 0.8, 0.3, 0.45) if valid else Color(0.9, 0.2, 0.2, 0.45)
	var half := int(floor(size_cells / 2.0))
	for dx in range(-half, -half + size_cells):
		for dy in range(-half, -half + size_cells):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not grid.is_in_bounds(cell):
				continue
			var rect := Rect2(cell.x * grid.cell_size, cell.y * grid.cell_size, grid.cell_size, grid.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _draw_square_top_left(drawer: Node2D, top_left: Vector2i, size_cells: int, valid: bool) -> void:
	var grid := _world.grid
	var color := Color(0.2, 0.8, 0.3, 0.45) if valid else Color(0.9, 0.2, 0.2, 0.45)
	for dx in range(size_cells):
		for dy in range(size_cells):
			var cell := Vector2i(top_left.x + dx, top_left.y + dy)
			if not grid.is_in_bounds(cell):
				continue
			var rect := Rect2(cell.x * grid.cell_size, cell.y * grid.cell_size, grid.cell_size, grid.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func save_map() -> void:
	if _editor_name_input == null:
		return
	var name := _editor_name_input.text.strip_edges()
	var data: Dictionary = build_map_data()
	var error := _validate_map_for_save(data)
	if error != "":
		set_status(error)
		return
	var MapIOScript: Script = load("res://scripts/MapIO.gd")
	var ok: bool = MapIOScript.call("save_map", name, data)
	if ok:
		map_data = data
		use_custom_map = true
		refresh_map_list(name)
		set_status("Saved: %s" % name)
	else:
		set_status("Save failed.")

func load_map() -> void:
	if _editor_name_input == null:
		return
	var name := _editor_name_input.text.strip_edges()
	var MapIOScript: Script = load("res://scripts/MapIO.gd")
	var data: Dictionary = MapIOScript.call("load_map", name)
	if data.is_empty():
		set_status("Load failed.")
		return
	if apply_map_data(data):
		map_data = data
		use_custom_map = true
		refresh_map_list(name)
		set_status("Loaded: %s" % name)
	else:
		set_status("Invalid map data.")

func export_campaign() -> void:
	var level_id := get_selected_campaign_level_id()
	if level_id == "":
		set_status("Select a campaign level to save.")
		return
	var data: Dictionary = build_map_data()
	var error := _validate_map_for_save(data)
	if error != "":
		set_status(error)
		return
	var path: String = save_campaign_level_to_id(level_id, data)
	if path == "":
		set_status("Save failed. Check campaign level data.")
	else:
		set_status("Saved campaign level: %s" % level_id)

func exit_to_menu() -> void:
	map_data = build_map_data()
	use_custom_map = not map_data.is_empty()
	_main._set_editor_active(false)
	_main._game_state_manager.set_splash_active(true)

func _has_resource_in_zone(resource_id: String, zone: String) -> bool:
	var def: Dictionary = _world.resources.defs.get(resource_id, {})
	var rightmost: int = int(def.get("validation_rightmost", 0))
	for node in _world.resources.nodes(resource_id):
		if node == null or not is_instance_valid(node):
			continue
		var cell_value = node.get("cell")
		if typeof(cell_value) != TYPE_VECTOR2I:
			continue
		var cell: Vector2i = cell_value
		if zone == "player_zone":
			if _world.grid.is_in_player_zone(cell):
				return true
		elif zone == "rightmost":
			if rightmost > 0 and cell.x >= max(_world.grid.grid_width - rightmost, 0):
				return true
	return false

func _validate_map_for_save(data: Dictionary) -> String:
	if data.is_empty():
		return "Map needs path + bases before saving."
	for resource_id in _world.resources.order:
		if not _world.resources.defs.has(resource_id):
			continue
		var def: Dictionary = _world.resources.defs[resource_id]
		var rightmost: int = int(def.get("validation_rightmost", 0))
		if rightmost <= 0:
			continue
		if not _has_resource_in_zone(resource_id, "rightmost"):
			var label: String = str(def.get("label", resource_id)).to_lower()
			return "Add at least 1 %s in the rightmost %d columns." % [label, min(rightmost, _world.grid.grid_width)]
	return ""

func build_map_data() -> Dictionary:
	var path := _world.path
	var grid := _world.grid
	if path.base_start_cell == Vector2i(-1, -1) or path.base_end_cell == Vector2i(-1, -1):
		return {}
	if path.cells.is_empty():
		return {}
	var data := {
		"grid_width": grid.grid_width,
		"grid_height": grid.grid_height,
		"path": _serialize_cells(path.cells),
		"base_start": [ path.base_start_cell.x, path.base_start_cell.y ],
		"base_end": [ path.base_end_cell.x, path.base_end_cell.y ],
		"enemy_towers": _serialize_cells(_collect_enemy_tower_cells()),
	}
	for resource_id in _world.resources.defs.keys():
		var def: Dictionary = _world.resources.defs[resource_id]
		var map_key: String = str(def.get("map_key", resource_id))
		data[map_key] = _serialize_cells(_collect_resource_cells(resource_id))
	return data

func refresh_campaign_level_list(select_id: String = "") -> void:
	if _editor_campaign_select == null:
		return
	var level_ids: Array[String] = CampaignManager.get_level_ids()
	_editor_campaign_select.clear()
	_editor_campaign_select.add_item("Select Level")
	_editor_campaign_select.set_item_metadata(0, "")
	for level_id in level_ids:
		var label := CampaignManager.get_level_name(level_id)
		var index := _editor_campaign_select.item_count
		_editor_campaign_select.add_item("%s (%s)" % [label, level_id])
		_editor_campaign_select.set_item_metadata(index, level_id)
	if select_id != "":
		for i in range(_editor_campaign_select.item_count):
			if _editor_campaign_select.get_item_metadata(i) == select_id:
				_editor_campaign_select.select(i)
				return
	_editor_campaign_select.select(0)

func get_selected_campaign_level_id() -> String:
	if _editor_campaign_select == null:
		return ""
	var idx := _editor_campaign_select.get_selected_id()
	var meta: Variant = _editor_campaign_select.get_item_metadata(idx)
	return "" if meta == null else str(meta)

func _build_campaign_map_data(map_data: Dictionary) -> Dictionary:
	if map_data.is_empty():
		return {}
	var campaign_map := {
		"grid_width": map_data.get("grid_width", 64),
		"grid_height": map_data.get("grid_height", 40),
		"path": map_data.get("path", []),
		"base_start": map_data.get("base_start", [-1, -1]),
		"base_end": map_data.get("base_end", [-1, -1]),
		"enemy_towers": map_data.get("enemy_towers", []),
		"auto_generate": false
	}
	for resource_id in _world.resources.defs.keys():
		var def: Dictionary = _world.resources.defs[resource_id]
		var map_key: String = str(def.get("map_key", resource_id))
		if map_data.has(map_key):
			campaign_map[map_key] = map_data[map_key]
	return campaign_map

func apply_map_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	var grid := _world.grid
	var path := _world.path
	grid.grid_width = int(data.get("grid_width", grid.grid_width))
	grid.grid_height = int(data.get("grid_height", grid.grid_height))
	_world.config.grid_width = grid.grid_width
	_world.config.grid_height = grid.grid_height
	path.cells = _parse_cells(data.get("path", []))
	path.base_start_cell = _parse_vec2i(data.get("base_start", []))
	path.base_end_cell = _parse_vec2i(data.get("base_end", []))
	_world.bases.clear()
	path.ordered_cells.clear()
	path.valid = false
	_main._rebuild_path()
	if _resource_spawner != null:
		var resource_cells: Dictionary = {}
		for resource_id in _world.resources.defs.keys():
			var def: Dictionary = _world.resources.defs[resource_id]
			var map_key: String = str(def.get("map_key", resource_id))
			resource_cells[resource_id] = _parse_cells(data.get(map_key, []))
		_resource_spawner.spawn_from_cells(resource_cells)
	_clear_enemy_towers()
	var enemy_cells := _parse_cells(data.get("enemy_towers", []))
	for cell in enemy_cells:
		if _can_place_enemy_tower(cell):
			_place_enemy_tower(cell)
	_main.queue_redraw()
	map_loaded.emit(data)
	return true

func _serialize_cells(cells) -> Array:
	var out: Array = []
	for cell in cells:
		out.append([cell.x, cell.y])
	return out

func _parse_cells(raw: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for entry in raw:
		if entry is Array and entry.size() >= 2:
			var x: int = int(entry[0])
			var y: int = int(entry[1])
			cells.append(Vector2i(x, y))
	return cells

func _parse_vec2i(raw) -> Vector2i:
	if raw is Array and raw.size() >= 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(-1, -1)

func _collect_enemy_tower_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in _world.occupancy.enemy_tower_by_cell.keys():
		cells.append(cell)
	return cells

func _collect_resource_cells(resource_id: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var seen: Dictionary = {}
	var nodes: Array = _world.resources.nodes(resource_id)
	for node in nodes:
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

func start_new_map() -> void:
	var path := _world.path
	path.cells.clear()
	path.ordered_cells.clear()
	path.valid = false
	path.base_start_cell = Vector2i(-1, -1)
	path.base_end_cell = Vector2i(-1, -1)
	_clear_enemy_towers()
	if _resource_spawner != null:
		_resource_spawner.clear_resources()
	_world.bases.clear()
	_main.queue_redraw()

func export_campaign_level(level_name: String) -> String:
	var map_data := build_map_data()
	if map_data.is_empty():
		return ""

	var campaign_map := _build_campaign_map_data(map_data)
	if campaign_map.is_empty():
		return ""

	var level_id := level_name.to_snake_case().replace(" ", "_")
	var campaign_level := {
		"id": level_id,
		"name": level_name if level_name != "" else "Custom Level",
		"campaign_order": 99,
		"max_base_level": 4,
		"available_units": ["grunt", "stone_thrower", "archer", "swordsman"],
		"available_buildings": ["grunt_tower", "archer_tower", "woodcutter", "stonecutter", "iron_miner", "house", "farm", "wood_storage", "food_storage", "stone_storage", "iron_storage", "archery_range", "barracks"],
		"difficulty_configs": {
			"easy": {
				"spawn_interval": 2.5,
				"enemy_hp_multiplier": 0.8,
				"enemy_damage_multiplier": 0.8,
				"starting_resources": {"wood": 35, "food": 5, "stone": 10, "iron": 5},
				"star_thresholds": {"time": 360, "base_hp_percent": 70, "units_lost": 15}
			},
			"medium": {
				"spawn_interval": 1.5,
				"enemy_hp_multiplier": 1.0,
				"enemy_damage_multiplier": 1.0,
				"starting_resources": {"wood": 25, "food": 3, "stone": 5, "iron": 0},
				"star_thresholds": {"time": 300, "base_hp_percent": 80, "units_lost": 10}
			},
			"hard": {
				"spawn_interval": 1.0,
				"enemy_hp_multiplier": 1.3,
				"enemy_damage_multiplier": 1.2,
				"starting_resources": {"wood": 20, "food": 0, "stone": 0, "iron": 0},
				"star_thresholds": {"time": 240, "base_hp_percent": 90, "units_lost": 5}
			}
		},
		"challenge_modes": [],
		"map_data": campaign_map
	}

	return JSON.stringify(campaign_level, "\t")

func save_campaign_level(level_name: String) -> String:
	var json_content := export_campaign_level(level_name)
	if json_content == "":
		return ""

	var level_id := level_name.to_snake_case().replace(" ", "_")
	if level_id == "":
		level_id = "custom_level"

	var path := "user://exported_%s.json" % level_id
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(json_content)
	file.close()

	DisplayServer.clipboard_set(json_content)

	return path

func save_campaign_level_to_id(level_id: String, map_data: Dictionary) -> String:
	if level_id == "":
		return ""
	if map_data.is_empty():
		return ""
	var campaign_map := _build_campaign_map_data(map_data)
	if campaign_map.is_empty():
		return ""
	var base_data := CampaignManager.get_level_data(level_id)
	if base_data.is_empty():
		return ""
	var updated := base_data.duplicate(true)
	updated["id"] = level_id
	updated["map_data"] = campaign_map
	var json_content := JSON.stringify(updated, "\t")
	var path := "res://data/campaign/levels/%s.json" % level_id
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(json_content)
	file.close()
	CampaignManager._load_levels()
	return path

func _place_enemy_tower(cell: Vector2i) -> void:
	var grid := _world.grid
	var script: Script = load("res://scripts/EnemyTower.gd")
	var tower: Node2D = script.new() as Node2D
	tower.set("cell", cell)
	tower.set("cell_size", grid.cell_size)
	_main.add_child(tower)
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
	for node in _main.get_tree().get_nodes_in_group("grunt_towers"):
		if node != null and is_instance_valid(node):
			node.queue_free()
