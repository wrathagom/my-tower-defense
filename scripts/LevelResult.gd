extends RefCounted
class_name LevelResult

var level_id: String = ""
var difficulty: String = ""
var victory: bool = false
var completion_time: float = 0.0
var base_hp_remaining: int = 0
var base_hp_max: int = 0
var units_lost: int = 0
var stars_earned: int = 0

func calculate_stars(thresholds: Dictionary) -> int:
	if not victory:
		return 0

	var stars := 0

	# Star 1: Complete the level
	stars += 1

	# Star 2: Time or base HP threshold
	var time_threshold: float = thresholds.get("time", 999999.0)
	var hp_percent_threshold: float = thresholds.get("base_hp_percent", 0.0)
	var hp_percent: float = 0.0
	if base_hp_max > 0:
		hp_percent = (float(base_hp_remaining) / float(base_hp_max)) * 100.0

	if completion_time <= time_threshold or hp_percent >= hp_percent_threshold:
		stars += 1

	# Star 3: Units lost threshold
	var units_lost_threshold: int = thresholds.get("units_lost", 999999)
	if units_lost <= units_lost_threshold:
		stars += 1

	stars_earned = stars
	return stars

func to_dict() -> Dictionary:
	return {
		"level_id": level_id,
		"difficulty": difficulty,
		"victory": victory,
		"completion_time": completion_time,
		"base_hp_remaining": base_hp_remaining,
		"base_hp_max": base_hp_max,
		"units_lost": units_lost,
		"stars_earned": stars_earned,
	}

static func from_dict(data: Dictionary) -> RefCounted:
	var script: Script = load("res://scripts/LevelResult.gd")
	var result: RefCounted = script.new()
	result.set("level_id", str(data.get("level_id", "")))
	result.set("difficulty", str(data.get("difficulty", "")))
	result.set("victory", bool(data.get("victory", false)))
	result.set("completion_time", float(data.get("completion_time", 0.0)))
	result.set("base_hp_remaining", int(data.get("base_hp_remaining", 0)))
	result.set("base_hp_max", int(data.get("base_hp_max", 0)))
	result.set("units_lost", int(data.get("units_lost", 0)))
	result.set("stars_earned", int(data.get("stars_earned", 0)))
	return result
