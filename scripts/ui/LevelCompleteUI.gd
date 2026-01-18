extends Control
class_name LevelCompleteUI

signal retry_pressed()
signal next_level_pressed()
signal level_select_pressed()
signal main_menu_pressed()

var _title_label: Label
var _stars_label: Label
var _time_label: Label
var _units_lost_label: Label
var _retry_button: Button
var _next_button: Button
var _select_button: Button
var _menu_button: Button
var _current_result: RefCounted

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -200
	panel.offset_right = 200
	panel.offset_top = -180
	panel.offset_bottom = 180
	add_child(panel)

	var main_box := VBoxContainer.new()
	main_box.alignment = BoxContainer.ALIGNMENT_CENTER
	main_box.add_theme_constant_override("separation", 12)
	panel.add_child(main_box)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(_title_label)

	_stars_label = Label.new()
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(_stars_label)

	var stats_box := VBoxContainer.new()
	stats_box.add_theme_constant_override("separation", 4)
	main_box.add_child(stats_box)

	_time_label = Label.new()
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(_time_label)

	_units_lost_label = Label.new()
	_units_lost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(_units_lost_label)

	var button_box := VBoxContainer.new()
	button_box.add_theme_constant_override("separation", 8)
	main_box.add_child(button_box)

	_retry_button = Button.new()
	_retry_button.text = "Retry"
	_retry_button.pressed.connect(_on_retry_pressed)
	button_box.add_child(_retry_button)

	_next_button = Button.new()
	_next_button.text = "Next Level"
	_next_button.pressed.connect(_on_next_pressed)
	button_box.add_child(_next_button)

	_select_button = Button.new()
	_select_button.text = "Level Select"
	_select_button.pressed.connect(_on_select_pressed)
	button_box.add_child(_select_button)

	_menu_button = Button.new()
	_menu_button.text = "Main Menu"
	_menu_button.pressed.connect(_on_menu_pressed)
	button_box.add_child(_menu_button)

func show_result(result: RefCounted) -> void:
	_current_result = result
	visible = true

	if result.victory:
		_title_label.text = "Victory!"
		_stars_label.text = _get_star_display(result.stars_earned)
	else:
		_title_label.text = "Defeat"
		_stars_label.text = ""

	var minutes := int(result.completion_time) / 60
	var seconds := int(result.completion_time) % 60
	_time_label.text = "Time: %d:%02d" % [minutes, seconds]
	_units_lost_label.text = "Units Lost: %d" % result.units_lost

	# Show/hide next level button based on availability
	var next_level := CampaignManager.get_next_level()
	_next_button.visible = result.victory and next_level != ""

func _get_star_display(stars: int) -> String:
	var filled := ""
	var empty := ""
	for i in range(stars):
		filled += "*"
	for i in range(3 - stars):
		empty += "-"
	return "Stars: %s%s (%d/3)" % [filled, empty, stars]

func hide_ui() -> void:
	visible = false

func _on_retry_pressed() -> void:
	hide_ui()
	retry_pressed.emit()

func _on_next_pressed() -> void:
	hide_ui()
	next_level_pressed.emit()

func _on_select_pressed() -> void:
	hide_ui()
	level_select_pressed.emit()

func _on_menu_pressed() -> void:
	hide_ui()
	main_menu_pressed.emit()
