extends Node
class_name UnitSpawner

const GameWorld = preload("res://scripts/state/GameWorld.gd")

var _main: Node
var _world: GameWorld
var _economy: Node
var _upgrade_manager: Node
var _performance_tracker: Node

func setup(main_node: Node, world: GameWorld, economy: Node, upgrade_manager: Node = null, performance_tracker: Node = null) -> void:
	_main = main_node
	_world = world
	_economy = economy
	_upgrade_manager = upgrade_manager
	_performance_tracker = performance_tracker

func spawn_unit(unit_id: String, unit_def: Dictionary) -> void:
	if _main == null or _economy == null or _world == null:
		return
	if _main._game_state_manager.is_game_over():
		return
	if not _world.path.valid or _world.path.ordered_cells.is_empty():
		return
	if not _is_unlocked(unit_def):
		return
	if not _economy.can_spawn_unit_def(unit_def):
		return
	_economy.on_unit_spawned_def(unit_def)
	var scene_path: String = unit_def.get("scene", "")
	if scene_path == "":
		return
	var unit: Node2D = load(scene_path).instantiate() as Node2D
	unit.path_points = _world.path.get_path_points_reversed(_world.grid)
	unit.reached_goal.connect(_main._on_unit_reached_goal.bind(unit))
	if unit.has_signal("died"):
		unit.died.connect(_main._on_unit_removed.bind(unit, unit_id))
	_main.add_child(unit)
	if _performance_tracker != null and _performance_tracker.is_tracking():
		_performance_tracker.record_unit_spawned(unit_id)

func _is_unlocked(unit_def: Dictionary) -> bool:
	if _upgrade_manager == null:
		return true
	var requirements: Array = unit_def.get("requirements", [])
	if requirements.is_empty():
		var min_level: int = unit_def.get("min_base_level", 1)
		if _upgrade_manager.base_level < min_level:
			return false
		var requires_range: bool = unit_def.get("requires_archery_range", false)
		var requires_upgrade: bool = unit_def.get("requires_archery_range_upgrade", false)
		if requires_range and _upgrade_manager.archery_range_level < 1:
			return false
		if requires_upgrade and _upgrade_manager.archery_range_level < 2:
			return false
		return true
	for req in requirements:
		if req is Dictionary:
			var req_type: String = str(req.get("type", ""))
			if req_type == "base_level":
				if _upgrade_manager.base_level < int(req.get("value", 1)):
					return false
			elif req_type == "archery_level":
				if _upgrade_manager.archery_range_level < int(req.get("value", 0)):
					return false
			elif req_type == "barracks_level":
				if _upgrade_manager.barracks_level < int(req.get("value", 0)):
					return false
	return true
