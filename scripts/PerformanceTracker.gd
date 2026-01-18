extends Node
class_name PerformanceTracker

var _start_time: float = 0.0
var _end_time: float = 0.0  # Captured when tracking stops
var _units_lost: int = 0
var _enemies_killed: int = 0
var _units_spawned: int = 0
var _units_by_type: Dictionary = {}  # unit_id -> { spawned, alive, lost }
var _is_tracking: bool = false

func start_tracking() -> void:
	_start_time = Time.get_ticks_msec() / 1000.0
	_units_lost = 0
	_enemies_killed = 0
	_units_spawned = 0
	_units_by_type.clear()
	_is_tracking = true

func stop_tracking() -> void:
	if _is_tracking:
		_end_time = Time.get_ticks_msec() / 1000.0
	_is_tracking = false

func reset() -> void:
	_start_time = 0.0
	_end_time = 0.0
	_units_lost = 0
	_enemies_killed = 0
	_units_spawned = 0
	_units_by_type.clear()
	_is_tracking = false

func record_unit_lost(unit_id: String = "") -> void:
	if _is_tracking:
		_units_lost += 1
		if unit_id != "" and _units_by_type.has(unit_id):
			_units_by_type[unit_id]["lost"] += 1
			_units_by_type[unit_id]["alive"] -= 1

func record_unit_spawned(unit_id: String = "") -> void:
	if _is_tracking:
		_units_spawned += 1
		if unit_id != "":
			if not _units_by_type.has(unit_id):
				_units_by_type[unit_id] = { "spawned": 0, "alive": 0, "lost": 0 }
			_units_by_type[unit_id]["spawned"] += 1
			_units_by_type[unit_id]["alive"] += 1

func record_enemy_killed() -> void:
	if _is_tracking:
		_enemies_killed += 1

func get_elapsed_time() -> float:
	if _is_tracking:
		return (Time.get_ticks_msec() / 1000.0) - _start_time
	elif _end_time > 0.0:
		return _end_time - _start_time
	return 0.0

func get_units_lost() -> int:
	return _units_lost

func is_tracking() -> bool:
	return _is_tracking

func get_enemies_killed() -> int:
	return _enemies_killed

func get_units_spawned() -> int:
	return _units_spawned

func get_units_by_type() -> Dictionary:
	return _units_by_type.duplicate(true)

func get_units_alive() -> int:
	return _units_spawned - _units_lost

func build_result(level_id: String, difficulty: String, victory: bool, base_hp: int, base_max_hp: int) -> RefCounted:
	var LevelResultScript: Script = load("res://scripts/LevelResult.gd")
	var result: RefCounted = LevelResultScript.new()
	result.level_id = level_id
	result.difficulty = difficulty
	result.victory = victory
	result.completion_time = get_elapsed_time()
	result.base_hp_remaining = base_hp
	result.base_hp_max = base_max_hp
	result.units_lost = _units_lost
	return result
