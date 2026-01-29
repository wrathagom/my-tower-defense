extends Node
class_name UiController

const PerformanceTracker = preload("res://scripts/PerformanceTracker.gd")
const Base = preload("res://scripts/Base.gd")

var hud_root: Control
var splash_panel: PanelContainer
var splash_play_button: Button
var splash_create_button: Button
var splash_exit_button: Button
var splash_campaign_button: Button
var splash_sandbox_button: Button
var splash_map_label: Label
var pause_panel: PanelContainer
var pause_resume_button: Button
var pause_exit_button: Button
var game_over_panel: PanelContainer
var game_over_label: Label
var game_over_button: Button
var game_over_exit_button: Button
var speed_button: Button
var upgrade_modal: PanelContainer
var upgrade_modal_title: Label
var upgrade_modal_level: Label
var upgrade_modal_cost: Label
var upgrade_modal_unlocks: Label
var upgrade_modal_button: Button
var upgrade_modal_close: Button
var build_label: Label
var build_category_box: HBoxContainer
var build_buttons_box: HBoxContainer
var spawn_units_box: VBoxContainer
var stats_panel: PanelContainer
var stats_base_level_label: Label
var stats_timer_label: Label
var stats_units_label: Label
var stats_enemies_label: Label
var stats_stars_box: VBoxContainer
var splash_map_select: OptionButton
var wood_label: Label
var food_label: Label
var stone_label: Label
var iron_label: Label
var unit_label: Label
var editor_panel: PanelContainer
var editor_name_input: LineEdit
var editor_campaign_select: OptionButton
var editor_status_label: Label
var editor_tool_label: Label

func validate() -> void:
	_validate_wiring()

func _validate_wiring() -> void:
	if hud_root == null:
		push_error("UiController missing hud_root")
	if splash_panel == null:
		push_error("UiController missing splash_panel")
	if pause_panel == null:
		push_error("UiController missing pause_panel")
	if game_over_panel == null:
		push_error("UiController missing game_over_panel")
	if speed_button == null:
		push_error("UiController missing speed_button")
	if stats_panel == null:
		push_error("UiController missing stats_panel")
	if build_label == null:
		push_error("UiController missing build_label")
	if editor_panel == null:
		push_error("UiController missing editor_panel")
	if editor_name_input == null:
		push_error("UiController missing editor_name_input")
	if editor_campaign_select == null:
		push_error("UiController missing editor_campaign_select")
	if editor_tool_label == null:
		push_error("UiController missing editor_tool_label")

func set_hud_visible(visible: bool) -> void:
	if hud_root != null:
		hud_root.visible = visible

func set_splash_visible(visible: bool) -> void:
	if splash_panel != null:
		splash_panel.visible = visible

func set_pause_visible(visible: bool) -> void:
	if pause_panel != null:
		pause_panel.visible = visible

func set_game_over_visible(visible: bool) -> void:
	if game_over_panel != null:
		game_over_panel.visible = visible

func set_game_over_text(text: String) -> void:
	if game_over_label != null:
		game_over_label.text = text

func set_speed_button_text(fast_forward: bool) -> void:
	if speed_button != null:
		speed_button.text = "Speed x2" if fast_forward else "Speed x1"

func set_build_label_text(text: String) -> void:
	if build_label != null:
		build_label.text = text

func update_stats(performance_tracker: PerformanceTracker, base_level: int, base_end: Base) -> void:
	if stats_panel == null:
		return
	if stats_base_level_label != null:
		stats_base_level_label.text = "Base Level: %d" % base_level
	if stats_timer_label != null and performance_tracker != null:
		var elapsed: float = performance_tracker.get_elapsed_time()
		var minutes: int = int(elapsed) / 60
		var seconds: int = int(elapsed) % 60
		stats_timer_label.text = "Time: %d:%02d" % [minutes, seconds]
	if stats_units_label != null and performance_tracker != null:
		var alive: int = performance_tracker.get_units_alive()
		var spawned: int = performance_tracker.get_units_spawned()
		var lost: int = performance_tracker.get_units_lost()
		stats_units_label.text = "Units: %d alive / %d spawned (%d lost)" % [alive, spawned, lost]
	if stats_enemies_label != null and performance_tracker != null:
		stats_enemies_label.text = "Enemies Killed: %d" % performance_tracker.get_enemies_killed()
	if stats_stars_box != null:
		_update_star_progress(performance_tracker, base_end)

func _update_star_progress(performance_tracker: PerformanceTracker, base_end: Base) -> void:
	if stats_stars_box == null:
		return
	for child in stats_stars_box.get_children():
		child.queue_free()
	if not CampaignManager.is_campaign_mode or CampaignManager.current_level_id == "":
		var hidden_label := Label.new()
		hidden_label.text = "(Campaign mode only)"
		hidden_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		stats_stars_box.add_child(hidden_label)
		return
	var thresholds := CampaignManager.get_star_thresholds(CampaignManager.current_level_id, CampaignManager.current_difficulty)
	if thresholds.is_empty():
		return
	var time_threshold: float = thresholds.get("time", 999999.0)
	var current_time: float = performance_tracker.get_elapsed_time() if performance_tracker != null else 0.0
	var time_ok := current_time <= time_threshold
	var time_label := Label.new()
	time_label.text = "%s Time: < %dm (%d:%02d)" % [
		"✓" if time_ok else "✗",
		int(time_threshold) / 60,
		int(current_time) / 60,
		int(current_time) % 60
	]
	time_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if time_ok else Color(0.9, 0.3, 0.3))
	stats_stars_box.add_child(time_label)
	var hp_percent_threshold: float = thresholds.get("base_hp_percent", 0.0)
	var current_hp_percent: float = 0.0
	if base_end != null and base_end.max_hp > 0:
		current_hp_percent = (float(base_end.hp) / float(base_end.max_hp)) * 100.0
	var hp_ok := current_hp_percent >= hp_percent_threshold
	var hp_label := Label.new()
	hp_label.text = "%s Base HP: > %d%% (%d%%)" % [
		"✓" if hp_ok else "✗",
		int(hp_percent_threshold),
		int(current_hp_percent)
	]
	hp_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if hp_ok else Color(0.9, 0.3, 0.3))
	stats_stars_box.add_child(hp_label)
	var units_lost_threshold: int = thresholds.get("units_lost", 999999)
	var current_units_lost: int = performance_tracker.get_units_lost() if performance_tracker != null else 0
	var units_ok := current_units_lost <= units_lost_threshold
	var units_label := Label.new()
	units_label.text = "%s Units Lost: < %d (%d)" % [
		"✓" if units_ok else "✗",
		units_lost_threshold,
		current_units_lost
	]
	units_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3) if units_ok else Color(0.9, 0.3, 0.3))
	stats_stars_box.add_child(units_label)
