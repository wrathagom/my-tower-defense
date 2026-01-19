class_name CampaignController
extends Node

signal level_started(level_id: String, difficulty: String, map_data: Dictionary)
signal level_retry_requested()
signal show_splash_requested()

var _main: Node
var _ui_controller

var _level_select_ui: Node
var _level_launch_ui: Node
var _level_complete_ui: Node

func setup(main_node: Node) -> void:
	_main = main_node
	if _main != null:
		_ui_controller = _main._ui_controller

func set_level_select_ui(ui: Node) -> void:
	_level_select_ui = ui
	if ui != null:
		ui.level_preview_requested.connect(_on_level_preview_requested)
		ui.back_pressed.connect(_on_level_select_back)

func set_level_launch_ui(ui: Node) -> void:
	_level_launch_ui = ui
	if ui != null:
		ui.play_pressed.connect(_on_level_selected)
		ui.back_pressed.connect(_on_level_launch_back)

func set_level_complete_ui(ui: Node) -> void:
	_level_complete_ui = ui
	if ui != null:
		ui.retry_pressed.connect(_on_level_retry)
		ui.next_level_pressed.connect(_on_next_level)
		ui.level_select_pressed.connect(_on_level_select_from_complete)
		ui.main_menu_pressed.connect(_on_main_menu_from_complete)

func show_campaign_select() -> void:
	if _ui_controller != null:
		_ui_controller.set_splash_visible(false)
	if _level_select_ui != null:
		_level_select_ui.visible = true
		if _level_select_ui.has_method("show_ui"):
			_level_select_ui.call("show_ui")

func show_level_complete(result: RefCounted) -> void:
	CampaignManager.record_level_completion(result)
	if _level_complete_ui != null and _level_complete_ui.has_method("show_result"):
		_level_complete_ui.call("show_result", result)
	else:
		push_error("LevelCompleteUI not available or missing show_result method")

func hide_all() -> void:
	if _level_select_ui != null:
		_level_select_ui.visible = false
	if _level_launch_ui != null:
		_level_launch_ui.visible = false
	if _level_complete_ui != null:
		_level_complete_ui.visible = false

# Internal signal handlers
func _on_level_preview_requested(level_id: String, difficulty: String) -> void:
	if _level_select_ui != null:
		_level_select_ui.visible = false
	if _level_launch_ui != null and _level_launch_ui.has_method("show_level"):
		_level_launch_ui.call("show_level", level_id, difficulty)

func _on_level_launch_back() -> void:
	if _level_launch_ui != null:
		_level_launch_ui.visible = false
	if _level_select_ui != null:
		_level_select_ui.visible = true

func _on_level_selected(level_id: String, difficulty: String) -> void:
	CampaignManager.start_campaign_level(level_id, difficulty)
	if _level_select_ui != null:
		_level_select_ui.visible = false
	if _level_launch_ui != null:
		_level_launch_ui.visible = false

	var map_data := CampaignManager.get_map_data(level_id)
	level_started.emit(level_id, difficulty, map_data)

func _on_level_select_back() -> void:
	if _level_select_ui != null:
		_level_select_ui.visible = false
	show_splash_requested.emit()

func _on_level_retry() -> void:
	if _level_complete_ui != null:
		_level_complete_ui.visible = false
	level_retry_requested.emit()

func _on_next_level() -> void:
	var next_level := CampaignManager.get_next_level()
	if next_level != "":
		_on_level_selected(next_level, "easy")

func _on_level_select_from_complete() -> void:
	if _level_complete_ui != null:
		_level_complete_ui.visible = false
	show_splash_requested.emit()
	show_campaign_select()

func _on_main_menu_from_complete() -> void:
	CampaignManager.exit_campaign()
	if _level_complete_ui != null:
		_level_complete_ui.visible = false
	show_splash_requested.emit()
