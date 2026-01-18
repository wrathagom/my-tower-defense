class_name MapEditor
extends Node

signal editor_activated()
signal editor_deactivated()
signal map_loaded(data: Dictionary)

var _main: Node
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
var _editor_status_label: Label
var _editor_tool_label: Label

func setup(main_node: Node, resource_spawner_node: Node) -> void:
	_main = main_node
	_resource_spawner = resource_spawner_node
	_sync_ui_refs()

func _sync_ui_refs() -> void:
	if _main == null:
		return
	_editor_panel = _main._editor_panel
	_editor_name_input = _main._editor_name_input
	_editor_status_label = _main._editor_status_label
	_editor_tool_label = _main._editor_tool_label

func is_active() -> bool:
	return active

func set_active(is_active: bool) -> void:
	active = is_active
	if _editor_panel != null:
		_editor_panel.visible = active
	if _main._hud_root != null:
		_main._hud_root.visible = not active
	if _main._game_over_panel != null:
		_main._game_over_panel.visible = false
	if _main._enemy_timer != null:
		if active:
			_main._enemy_timer.stop()
		else:
			_main._enemy_timer.start()
	if active:
		_main._game_state_manager.set_paused(false)
		_main._game_state_manager.set_fast_forward(false)
		_main._clear_units()
		_main._clear_constructions()
		_main._clear_buildings()
		_main._clear_enemy_towers()
		if _resource_spawner != null:
			_resource_spawner.clear_resources()
		_main._clear_bases()
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
			var def: Dictionary = _main._resource_defs.get(tool, {})
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
	if _main._splash_map_select == null:
		return
	_main._splash_map_select.clear()
	_main._splash_map_select.add_item("Random")
	for name in map_list:
		_main._splash_map_select.add_item(name)
	if select_name != "" and map_list.has(select_name):
		var index := map_list.find(select_name)
		_main._splash_map_select.select(index + 1)
	else:
		_main._splash_map_select.select(0)

func get_selected_map_name() -> String:
	if _main._splash_map_select == null:
		return ""
	var idx: int = _main._splash_map_select.get_selected_id()
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
	var cell := Vector2i(int(world_pos.x / _main.cell_size), int(world_pos.y / _main.cell_size))
	if not _main._is_in_bounds(cell):
		return
	if tool == "path":
		if _main._resource_cell_has_any(cell):
			return
		if not _main.path_cells.has(cell):
			_main.path_cells.append(cell)
		_main._rebuild_path()
		_main.queue_redraw()
		return
	if tool == "erase":
		if _resource_spawner != null:
			if _resource_spawner.remove_resource_at(cell):
				_main.queue_redraw()
				return
		if _main._remove_enemy_tower_at(cell):
			_main.queue_redraw()
			return
		if _main.path_cells.has(cell):
			_main.path_cells.erase(cell)
			_main._rebuild_path()
			_main.queue_redraw()
			return
		if _main._base_start_cell != Vector2i(-1, -1) and _is_in_base_area(_main._base_start_cell, cell):
			_main._base_start_cell = Vector2i(-1, -1)
		if _main._base_end_cell != Vector2i(-1, -1) and _is_in_base_area(_main._base_end_cell, cell):
			_main._base_end_cell = Vector2i(-1, -1)
		if _main._base_start_cell == Vector2i(-1, -1) or _main._base_end_cell == Vector2i(-1, -1):
			_main._rebuild_path()
			_main.queue_redraw()
		return
	if tool == "base_start" or tool == "base_end":
		if not _can_place_base(cell, tool):
			return
		if tool == "base_start":
			_main._base_end_cell = cell
		else:
			_main._base_start_cell = cell
		if not _main.path_cells.has(cell):
			_main.path_cells.append(cell)
		_main._rebuild_path()
		_main.queue_redraw()
		return
	if tool == "enemy_tower":
		if not _can_place_enemy_tower(cell):
			return
		_main._place_enemy_tower(cell)
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
	var cell := Vector2i(int(world_pos.x / _main.cell_size), int(world_pos.y / _main.cell_size))
	if cell == last_cell:
		return
	last_cell = cell
	handle_click(world_pos)

func _can_place_base(center: Vector2i, kind: String) -> bool:
	if kind == "base_start" and not _main._is_in_player_zone(center):
		return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not _main._is_in_bounds(cell):
				return false
			if _main._resource_cell_has_any(cell):
				return false
			if _main.path_cells.has(cell) and cell != center:
				return false
			if _main._base_start_cell != Vector2i(-1, -1) and _is_in_base_area(_main._base_start_cell, cell):
				return false
			if _main._base_end_cell != Vector2i(-1, -1) and _is_in_base_area(_main._base_end_cell, cell):
				return false
	return true

func _is_in_base_area(center: Vector2i, cell: Vector2i) -> bool:
	return abs(center.x - cell.x) <= 1 and abs(center.y - cell.y) <= 1

func _can_place_enemy_tower(cell: Vector2i) -> bool:
	if not _main._is_in_bounds(cell):
		return false
	if _main._is_base_cell(cell):
		return false
	if _main.path_cells.has(cell):
		return false
	if _main._resource_cell_has_any(cell):
		return false
	if _main._enemy_tower_by_cell.has(cell):
		return false
	return true

func _is_resource_tool(t: String) -> bool:
	return _main._resource_defs.has(t)

func draw(drawer: Node2D) -> void:
	if not active:
		return
	_draw_hover(drawer)

func _draw_hover(drawer: Node2D) -> void:
	if tool == "base_start" or tool == "base_end":
		var cell := _mouse_cell()
		if not _main._is_in_bounds(cell):
			return
		var valid: bool = _can_place_base(cell, tool)
		_draw_square(drawer, cell, 3, valid)
	elif tool == "path":
		var cell := _mouse_cell()
		if not _main._is_in_bounds(cell):
			return
		if _main._resource_cell_has_any(cell):
			return
		_draw_square(drawer, cell, 1, true)
	elif _is_resource_tool(tool):
		var cell := _mouse_cell()
		if not _main._is_in_bounds(cell):
			return
		var valid: bool = true
		if _main._resource_cell_has_any(cell):
			valid = false
		if _main.path_cells.has(cell) or _main._is_base_cell(cell):
			valid = false
		_draw_square_top_left(drawer, cell, 2, valid)
	elif tool == "enemy_tower":
		var cell := _mouse_cell()
		if not _main._is_in_bounds(cell):
			return
		var valid: bool = _can_place_enemy_tower(cell)
		_draw_square(drawer, cell, 1, valid)
	elif tool == "erase":
		var cell := _mouse_cell()
		if not _main._is_in_bounds(cell):
			return
		var valid: bool = _main._resource_cell_has_any(cell) or _main.path_cells.has(cell) or _main._is_base_cell(cell) or _main._enemy_tower_by_cell.has(cell)
		_draw_square(drawer, cell, 1, valid)

func _mouse_cell() -> Vector2i:
	var world_pos: Vector2 = _main.get_global_mouse_position()
	return Vector2i(int(world_pos.x / _main.cell_size), int(world_pos.y / _main.cell_size))

func _draw_square(drawer: Node2D, center: Vector2i, size_cells: int, valid: bool) -> void:
	var color := Color(0.2, 0.8, 0.3, 0.45) if valid else Color(0.9, 0.2, 0.2, 0.45)
	var half := int(floor(size_cells / 2.0))
	for dx in range(-half, -half + size_cells):
		for dy in range(-half, -half + size_cells):
			var cell := Vector2i(center.x + dx, center.y + dy)
			if not _main._is_in_bounds(cell):
				continue
			var rect := Rect2(cell.x * _main.cell_size, cell.y * _main.cell_size, _main.cell_size, _main.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func _draw_square_top_left(drawer: Node2D, top_left: Vector2i, size_cells: int, valid: bool) -> void:
	var color := Color(0.2, 0.8, 0.3, 0.45) if valid else Color(0.9, 0.2, 0.2, 0.45)
	for dx in range(size_cells):
		for dy in range(size_cells):
			var cell := Vector2i(top_left.x + dx, top_left.y + dy)
			if not _main._is_in_bounds(cell):
				continue
			var rect := Rect2(cell.x * _main.cell_size, cell.y * _main.cell_size, _main.cell_size, _main.cell_size)
			drawer.draw_rect(rect, color, true)
			drawer.draw_rect(rect, color.darkened(0.4), false, 2.0)

func build_map_data() -> Dictionary:
	if _main._base_start_cell == Vector2i(-1, -1) or _main._base_end_cell == Vector2i(-1, -1):
		return {}
	if _main.path_cells.is_empty():
		return {}
	var data := {
		"grid_width": _main.grid_width,
		"grid_height": _main.grid_height,
		"path": _serialize_cells(_main.path_cells),
		"base_start": [ _main._base_start_cell.x, _main._base_start_cell.y ],
		"base_end": [ _main._base_end_cell.x, _main._base_end_cell.y ],
		"enemy_towers": _serialize_cells(_collect_enemy_tower_cells()),
	}
	for resource_id in _main._resource_defs.keys():
		var def: Dictionary = _main._resource_defs[resource_id]
		var map_key: String = str(def.get("map_key", resource_id))
		data[map_key] = _serialize_cells(_main._collect_resource_cells(resource_id))
	return data

func apply_map_data(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	_main.grid_width = int(data.get("grid_width", _main.grid_width))
	_main.grid_height = int(data.get("grid_height", _main.grid_height))
	_main.path_cells = _parse_cells(data.get("path", []))
	_main._base_start_cell = _parse_vec2i(data.get("base_start", []))
	_main._base_end_cell = _parse_vec2i(data.get("base_end", []))
	_main._clear_bases()
	_main._ordered_path_cells.clear()
	_main._path_valid = false
	_main._rebuild_path()
	if _resource_spawner != null:
		var resource_cells: Dictionary = {}
		for resource_id in _main._resource_defs.keys():
			var def: Dictionary = _main._resource_defs[resource_id]
			var map_key: String = str(def.get("map_key", resource_id))
			resource_cells[resource_id] = _parse_cells(data.get(map_key, []))
		_resource_spawner.spawn_from_cells(resource_cells)
	_main._clear_enemy_towers()
	var enemy_cells := _parse_cells(data.get("enemy_towers", []))
	for cell in enemy_cells:
		if _can_place_enemy_tower(cell):
			_main._place_enemy_tower(cell)
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
	for cell in _main._enemy_tower_by_cell.keys():
		cells.append(cell)
	return cells

func start_new_map() -> void:
	_main.path_cells.clear()
	_main._ordered_path_cells.clear()
	_main._path_valid = false
	_main._base_start_cell = Vector2i(-1, -1)
	_main._base_end_cell = Vector2i(-1, -1)
	_main._clear_enemy_towers()
	if _resource_spawner != null:
		_resource_spawner.clear_resources()
	_main._clear_bases()
	_main.queue_redraw()
