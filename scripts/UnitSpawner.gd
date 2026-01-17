extends Node
class_name UnitSpawner

var main: Node
var economy: Node

func setup(main_node: Node, economy_node: Node) -> void:
	main = main_node
	economy = economy_node

func spawn_unit(unit_id: String, unit_def: Dictionary) -> void:
	if main == null or economy == null:
		return
	if main._game_over:
		return
	if not main._path_valid or main._ordered_path_cells.is_empty():
		return
	if not _is_unlocked(unit_def):
		return
	if not economy.can_spawn_unit_def(unit_def):
		return
	economy.on_unit_spawned_def(unit_def)
	var scene_path: String = unit_def.get("scene", "")
	if scene_path == "":
		return
	var unit: Node2D = load(scene_path).instantiate() as Node2D
	unit.path_points = main._get_path_points_reversed()
	unit.reached_goal.connect(main._on_unit_reached_goal.bind(unit))
	if unit.has_signal("died"):
		unit.died.connect(main._on_unit_removed.bind(unit))
	main.add_child(unit)

func _is_unlocked(unit_def: Dictionary) -> bool:
	var min_level: int = unit_def.get("min_base_level", 1)
	if main._base_level < min_level:
		return false
	var requires_range: bool = unit_def.get("requires_archery_range", false)
	if requires_range and not _has_active_archery_range():
		return false
	var requires_upgrade: bool = unit_def.get("requires_archery_range_upgrade", false)
	if requires_upgrade and not main._has_archery_range_upgrade:
		return false
	return true

func _has_active_archery_range() -> bool:
	for range in main._archery_ranges:
		if range != null and is_instance_valid(range):
			return true
	return false
