extends Node

const LEVELS_DIR := "res://data/campaign/levels"
const PROGRESS_PATH := "user://campaign_progress.json"
const DIFFICULTIES := ["easy", "medium", "hard"]

signal level_completed(result: RefCounted)
signal progress_changed()

var _levels: Dictionary = {}  # level_id -> level data
var _level_order: Array[String] = []  # level IDs in campaign order
var _progress: Dictionary = {}  # level_id -> { difficulty -> { stars, best_time, completed } }

var current_level_id: String = ""
var current_difficulty: String = "easy"
var is_campaign_mode: bool = false

func _ready() -> void:
	_load_levels()
	_load_progress()

func _load_levels() -> void:
	_levels.clear()
	_level_order.clear()

	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_warning("CampaignManager: Could not open levels directory: %s" % LEVELS_DIR)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var path := "%s/%s" % [LEVELS_DIR, file_name]
			var level_data := _load_level_file(path)
			if not level_data.is_empty():
				var level_id: String = str(level_data.get("id", file_name.trim_suffix(".json")))
				_levels[level_id] = level_data
		file_name = dir.get_next()
	dir.list_dir_end()

	# Sort levels by campaign_order
	var sorted: Array = _levels.keys()
	sorted.sort_custom(func(a, b):
		var order_a: int = int(_levels[a].get("campaign_order", 999))
		var order_b: int = int(_levels[b].get("campaign_order", 999))
		return order_a < order_b
	)
	for level_id in sorted:
		_level_order.append(str(level_id))

func _load_level_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("CampaignManager: Could not open level file: %s" % path)
		return {}
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("CampaignManager: Invalid JSON in level file: %s" % path)
		return {}
	return parsed

func _load_progress() -> void:
	_progress.clear()
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) == TYPE_DICTIONARY:
		_progress = parsed

func _save_progress() -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		push_warning("CampaignManager: Could not access user:// directory")
		return
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("CampaignManager: Could not save progress to: %s" % PROGRESS_PATH)
		return
	var json := JSON.stringify(_progress, "\t")
	file.store_string(json)
	file.close()

# Level access
func get_level_count() -> int:
	return _level_order.size()

func get_level_ids() -> Array[String]:
	return _level_order.duplicate()

func get_level_data(level_id: String) -> Dictionary:
	return _levels.get(level_id, {})

func get_level_name(level_id: String) -> String:
	var data := get_level_data(level_id)
	return str(data.get("name", level_id))

func get_level_by_order(order: int) -> String:
	if order < 0 or order >= _level_order.size():
		return ""
	return _level_order[order]

# Difficulty config
func get_difficulty_config(level_id: String, difficulty: String) -> Dictionary:
	var level_data := get_level_data(level_id)
	var configs: Dictionary = level_data.get("difficulty_configs", {})
	return configs.get(difficulty, {})

func get_spawn_interval(level_id: String, difficulty: String) -> float:
	var config := get_difficulty_config(level_id, difficulty)
	return float(config.get("spawn_interval", 1.5))

func get_enemy_hp_multiplier(level_id: String, difficulty: String) -> float:
	var config := get_difficulty_config(level_id, difficulty)
	return float(config.get("enemy_hp_multiplier", 1.0))

func get_enemy_damage_multiplier(level_id: String, difficulty: String) -> float:
	var config := get_difficulty_config(level_id, difficulty)
	return float(config.get("enemy_damage_multiplier", 1.0))

func get_enemy_base_hp_multiplier(level_id: String, difficulty: String) -> float:
	var config := get_difficulty_config(level_id, difficulty)
	return float(config.get("enemy_base_hp_multiplier", 1.0))

func get_starting_resources(level_id: String, difficulty: String) -> Dictionary:
	var config := get_difficulty_config(level_id, difficulty)
	return config.get("starting_resources", {"wood": 20, "food": 0, "stone": 0, "iron": 0})

func get_star_thresholds(level_id: String, difficulty: String) -> Dictionary:
	var config := get_difficulty_config(level_id, difficulty)
	return config.get("star_thresholds", {})

# Level restrictions
func get_max_base_level(level_id: String) -> int:
	var level_data := get_level_data(level_id)
	return int(level_data.get("max_base_level", 4))

func get_available_units(level_id: String) -> Array:
	var level_data := get_level_data(level_id)
	return level_data.get("available_units", [])

func get_available_buildings(level_id: String) -> Array:
	var level_data := get_level_data(level_id)
	return level_data.get("available_buildings", [])

func get_map_data(level_id: String) -> Dictionary:
	var level_data := get_level_data(level_id)
	return level_data.get("map_data", {})

# Unlock logic
func is_level_unlocked(level_id: String) -> bool:
	var order := _level_order.find(level_id)
	if order == -1:
		return false
	# First level is always unlocked
	if order == 0:
		return true
	# Unlock if previous level completed on any difficulty
	var prev_level := _level_order[order - 1]
	return is_level_completed(prev_level)

func is_difficulty_unlocked(level_id: String, difficulty: String) -> bool:
	if not is_level_unlocked(level_id):
		return false
	# Easy is always unlocked if level is unlocked
	if difficulty == "easy":
		return true
	# Medium requires Easy completion
	if difficulty == "medium":
		return is_difficulty_completed(level_id, "easy")
	# Hard requires Medium completion
	if difficulty == "hard":
		return is_difficulty_completed(level_id, "medium")
	return false

func is_level_completed(level_id: String) -> bool:
	var level_progress: Dictionary = _progress.get(level_id, {})
	for diff in DIFFICULTIES:
		var diff_progress: Dictionary = level_progress.get(diff, {})
		if diff_progress.get("completed", false):
			return true
	return false

func is_difficulty_completed(level_id: String, difficulty: String) -> bool:
	var level_progress: Dictionary = _progress.get(level_id, {})
	var diff_progress: Dictionary = level_progress.get(difficulty, {})
	return diff_progress.get("completed", false)

func get_stars(level_id: String, difficulty: String) -> int:
	var level_progress: Dictionary = _progress.get(level_id, {})
	var diff_progress: Dictionary = level_progress.get(difficulty, {})
	return int(diff_progress.get("stars", 0))

func get_total_stars() -> int:
	var total := 0
	for level_id in _level_order:
		for diff in DIFFICULTIES:
			total += get_stars(level_id, diff)
	return total

func get_best_time(level_id: String, difficulty: String) -> float:
	var level_progress: Dictionary = _progress.get(level_id, {})
	var diff_progress: Dictionary = level_progress.get(difficulty, {})
	return float(diff_progress.get("best_time", 0.0))

# Progress recording
func record_level_completion(result: RefCounted) -> void:
	var level_id: String = str(result.get("level_id"))
	if level_id == "":
		return

	var difficulty: String = str(result.get("difficulty"))

	# Get star thresholds and calculate stars
	var thresholds := get_star_thresholds(level_id, difficulty)
	if result.has_method("calculate_stars"):
		result.calculate_stars(thresholds)

	# Update progress
	if not _progress.has(level_id):
		_progress[level_id] = {}
	var level_progress: Dictionary = _progress[level_id]

	if not level_progress.has(difficulty):
		level_progress[difficulty] = {}
	var diff_progress: Dictionary = level_progress[difficulty]

	# Only update if victory or better result
	var victory: bool = bool(result.get("victory"))
	if victory:
		var prev_stars: int = int(diff_progress.get("stars", 0))
		var prev_time: float = float(diff_progress.get("best_time", 999999.0))
		var stars_earned: int = int(result.get("stars_earned"))
		var completion_time: float = float(result.get("completion_time"))

		diff_progress["completed"] = true
		if stars_earned > prev_stars:
			diff_progress["stars"] = stars_earned
		if completion_time < prev_time:
			diff_progress["best_time"] = completion_time

	_save_progress()
	level_completed.emit(result)
	progress_changed.emit()

# Campaign state
func start_campaign_level(level_id: String, difficulty: String) -> void:
	if not _levels.has(level_id):
		push_warning("CampaignManager: Unknown level: %s" % level_id)
		return
	current_level_id = level_id
	current_difficulty = difficulty
	is_campaign_mode = true

func exit_campaign() -> void:
	current_level_id = ""
	current_difficulty = "easy"
	is_campaign_mode = false

func get_next_level() -> String:
	if current_level_id == "":
		return ""
	var order := _level_order.find(current_level_id)
	if order == -1 or order + 1 >= _level_order.size():
		return ""
	var next_level := _level_order[order + 1]
	if is_level_unlocked(next_level):
		return next_level
	return ""

# Reset progress (for testing/debug)
func reset_progress() -> void:
	_progress.clear()
	_save_progress()
	progress_changed.emit()
