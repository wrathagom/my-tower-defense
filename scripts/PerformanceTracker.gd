extends Node
class_name PerformanceTracker

var _start_time: float = 0.0
var _units_lost: int = 0
var _is_tracking: bool = false

func start_tracking() -> void:
	_start_time = Time.get_ticks_msec() / 1000.0
	_units_lost = 0
	_is_tracking = true

func stop_tracking() -> void:
	_is_tracking = false

func reset() -> void:
	_start_time = 0.0
	_units_lost = 0
	_is_tracking = false

func record_unit_lost() -> void:
	if _is_tracking:
		_units_lost += 1

func get_elapsed_time() -> float:
	if not _is_tracking:
		return 0.0
	return (Time.get_ticks_msec() / 1000.0) - _start_time

func get_units_lost() -> int:
	return _units_lost

func is_tracking() -> bool:
	return _is_tracking

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
