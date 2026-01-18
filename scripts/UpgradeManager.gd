class_name UpgradeManager
extends Node

signal base_upgraded(new_level: int)

var _main: Node
var _economy: Node

var base_level := 1
var base_upgrade_in_progress := false
var archery_range_level := 0
var archery_ranges: Array[Node2D] = []
var barracks_level := 0

var _upgrade_modal: PanelContainer
var _upgrade_modal_title: Label
var _upgrade_modal_level: Label
var _upgrade_modal_cost: Label
var _upgrade_modal_unlocks: Label
var _upgrade_modal_button: Button
var _upgrade_modal_close: Button
var _upgrade_modal_target: Node2D
var _upgrade_modal_type := ""

func setup(main_node: Node, economy_node: Node) -> void:
	_main = main_node
	_economy = economy_node
	_sync_ui_refs()

func _sync_ui_refs() -> void:
	if _main == null:
		return
	_upgrade_modal = _main._upgrade_modal
	_upgrade_modal_title = _main._upgrade_modal_title
	_upgrade_modal_level = _main._upgrade_modal_level
	_upgrade_modal_cost = _main._upgrade_modal_cost
	_upgrade_modal_unlocks = _main._upgrade_modal_unlocks
	_upgrade_modal_button = _main._upgrade_modal_button
	_upgrade_modal_close = _main._upgrade_modal_close

func show_upgrade_modal(kind: String, target: Node2D) -> void:
	if _upgrade_modal == null:
		return
	_upgrade_modal_type = kind
	_upgrade_modal_target = target
	set_upgrade_modal_visible(true)
	update_upgrade_modal()

func set_upgrade_modal_visible(visible: bool) -> void:
	if _upgrade_modal != null:
		_upgrade_modal.visible = visible
	if not visible:
		_upgrade_modal_type = ""
		_upgrade_modal_target = null

func update_upgrade_modal() -> void:
	if _upgrade_modal == null or not _upgrade_modal.visible:
		return
	if _upgrade_modal_type == "base":
		_upgrade_modal_title.text = "Upgrade Base"
		_upgrade_modal_level.text = "Level: %d / %d" % [base_level, base_max_level()]
		_upgrade_modal_cost.text = "Cost: %s" % base_upgrade_cost_text()
		_upgrade_modal_unlocks.text = "Unlocks: %s" % base_upgrade_unlocks()
		_upgrade_modal_button.disabled = not can_upgrade_base()
	elif _upgrade_modal_type == "archery_range":
		var range := _upgrade_modal_target
		var level_value := 1
		if range != null and is_instance_valid(range) and range.get("level") != null:
			level_value = int(range.get("level"))
		_upgrade_modal_title.text = "Upgrade Archery Range"
		_upgrade_modal_level.text = "Level: %d / %d" % [level_value, 2]
		_upgrade_modal_cost.text = "Cost: %dW %dS" % [_main.archery_range_upgrade_cost, _main.archery_range_upgrade_stone_cost]
		_upgrade_modal_unlocks.text = "Unlocks: Archer, Archer Tower"
		_upgrade_modal_button.disabled = not can_upgrade_archery(range)
	else:
		_upgrade_modal_title.text = "Upgrade"
		_upgrade_modal_level.text = "Level: -"
		_upgrade_modal_cost.text = "Cost: -"
		_upgrade_modal_unlocks.text = "Unlocks: -"
		_upgrade_modal_button.disabled = true

func get_upgrade_modal_type() -> String:
	return _upgrade_modal_type

func get_upgrade_modal_target() -> Node2D:
	return _upgrade_modal_target

func base_max_level() -> int:
	if _main == null or _main.base_upgrade_times.is_empty():
		return 1
	return _main.base_upgrade_times.size() + 1

func base_upgrade_cost_text() -> String:
	if _main == null:
		return ""
	if base_level >= 2:
		return "%dW %dS" % [_main.base_upgrade_cost, _main.base_upgrade_stone_cost]
	return "%dW" % _main.base_upgrade_cost

func base_upgrade_unlocks() -> String:
	if base_level == 1:
		return "Stonecutter, Archery Range, Stone Storage, Stone Thrower"
	if base_level == 2:
		return "Iron Miner, Iron Storage"
	if base_level >= 3:
		return "More build radius"
	return "-"

func can_upgrade_base() -> bool:
	if _main == null or _main._base_end == null:
		return false
	if base_upgrade_in_progress:
		return false
	if base_level >= base_max_level():
		return false
	if _economy == null or not _economy.can_afford_wood(_main.base_upgrade_cost):
		return false
	if base_level >= 2 and _economy.stone < _main.base_upgrade_stone_cost:
		return false
	return true

func can_upgrade_archery(range: Node2D) -> bool:
	if range == null or not is_instance_valid(range):
		return false
	if archery_range_level >= 2:
		return false
	if range.get("upgrade_in_progress") == true:
		return false
	if _economy == null or not _economy.can_afford_wood(_main.archery_range_upgrade_cost):
		return false
	if _economy.stone < _main.archery_range_upgrade_stone_cost:
		return false
	return true

func try_upgrade_base() -> void:
	if not can_upgrade_base():
		return
	_economy.spend_wood(_main.base_upgrade_cost)
	if base_level >= 2:
		_economy.spend_stone(_main.base_upgrade_stone_cost)
	base_upgrade_in_progress = true
	_economy.set_base_upgrade_in_progress(true)
	var top_left: Vector2i = _main._base_end_cell + Vector2i(-1, -1)
	var duration := base_upgrade_duration()
	var construction = _main._spawn_construction(top_left, 3, duration)
	construction.completed.connect(finish_base_upgrade)

func base_upgrade_duration() -> float:
	if _main == null or _main.base_upgrade_times.is_empty():
		return 0.0
	var index: int = max(base_level - 1, 0)
	if index >= _main.base_upgrade_times.size():
		index = _main.base_upgrade_times.size() - 1
	return _main.base_upgrade_times[index]

func finish_base_upgrade() -> void:
	base_level += 1
	_main.player_zone_width += _main.zone_upgrade_amount
	_main._base_end.upgrade(_main.base_hp_upgrade)
	base_upgrade_in_progress = false
	_main._update_base_label()
	_main._update_enemy_spawn_rate()
	_economy.update_buttons_for_base_level(base_level, archery_range_level, barracks_level)
	_economy.set_base_upgrade_in_progress(false)
	update_base_upgrade_indicator()
	_economy.set_archery_level(archery_range_level)
	base_upgraded.emit(base_level)

func try_upgrade_archery_range(range: Node2D) -> void:
	if not can_upgrade_archery(range):
		return
	_economy.spend_wood(_main.archery_range_upgrade_cost)
	_economy.spend_stone(_main.archery_range_upgrade_stone_cost)
	range.set("upgrade_in_progress", true)
	var top_left: Vector2i = range.get("cell")
	var construction = _main._spawn_construction(top_left, 3, _main.archery_range_upgrade_time)
	construction.completed.connect(Callable(self, "finish_archery_range_upgrade").bind(range))

func finish_archery_range_upgrade(range: Node2D) -> void:
	if range == null or not is_instance_valid(range):
		return
	range.set("upgrade_in_progress", false)
	if range.has_method("upgrade"):
		range.call("upgrade")
	archery_range_level = max(archery_range_level, 2)
	_economy.set_archery_level(archery_range_level)
	update_archery_range_indicators()

func update_archery_range_indicators() -> void:
	for range in archery_ranges:
		if range == null or not is_instance_valid(range):
			continue
		var show: bool = archery_range_level < 2 and range.get("upgrade_in_progress") != true
		var can_upgrade: bool = can_upgrade_archery(range)
		if range.has_method("set_upgrade_indicator"):
			var cost_text := "%dW %dS" % [_main.archery_range_upgrade_cost, _main.archery_range_upgrade_stone_cost]
			range.call("set_upgrade_indicator", show, can_upgrade, cost_text)

func register_archery_range(range: Node2D) -> void:
	archery_ranges.append(range)
	var level_value: int = 1
	if range.get("level") != null:
		level_value = int(range.get("level"))
	archery_range_level = max(archery_range_level, level_value)
	if _economy != null:
		_economy.set_archery_level(archery_range_level)
	update_archery_range_indicators()

func register_barracks(barracks: Node2D) -> void:
	if barracks == null:
		return
	barracks_level = max(barracks_level, 1)
	if _economy != null:
		_economy.set_barracks_level(barracks_level)
		_economy.update_buttons_for_base_level(base_level, archery_range_level, barracks_level)

func update_base_upgrade_indicator() -> void:
	if _main == null or _main._base_end == null:
		return
	var can_upgrade := can_upgrade_base()
	var show := not base_upgrade_in_progress and base_level < base_max_level()
	var cost_text := base_upgrade_cost_text()
	_main._base_end.set_upgrade_indicator(show, can_upgrade, cost_text)

func get_archery_range_at(world_pos: Vector2) -> Node2D:
	if _main == null:
		return null
	for range in archery_ranges:
		if range == null or not is_instance_valid(range):
			continue
		var size: float = _main.cell_size * 3.0
		var local := world_pos - range.position
		if local.x >= 0.0 and local.y >= 0.0 and local.x <= size and local.y <= size:
			return range
	return null

func reset() -> void:
	archery_ranges.clear()
	archery_range_level = 0
	barracks_level = 0
	base_upgrade_in_progress = false
	if _economy != null:
		_economy.set_archery_level(archery_range_level)
		_economy.set_barracks_level(barracks_level)
