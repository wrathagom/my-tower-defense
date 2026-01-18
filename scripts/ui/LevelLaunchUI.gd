extends Control
class_name LevelLaunchUI

signal play_pressed(level_id: String, difficulty: String)
signal back_pressed()

var _level_id: String = ""
var _difficulty: String = ""
var _title_label: Label
var _lore_label: Label
var _requirements_box: VBoxContainer
var _play_button: Button
var _back_button: Button

func _ready() -> void:
	_build_ui()
	visible = false

func _build_ui() -> void:
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0

	var main_panel := PanelContainer.new()
	main_panel.anchor_left = 0.5
	main_panel.anchor_right = 0.5
	main_panel.anchor_top = 0.5
	main_panel.anchor_bottom = 0.5
	main_panel.offset_left = -280
	main_panel.offset_right = 280
	main_panel.offset_top = -220
	main_panel.offset_bottom = 220
	add_child(main_panel)

	var main_box := VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 16)
	main_panel.add_child(main_box)

	# Title
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 24)
	main_box.add_child(_title_label)

	# Difficulty label
	var diff_label := Label.new()
	diff_label.name = "DifficultyLabel"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_box.add_child(diff_label)

	# Lore section
	var lore_panel := PanelContainer.new()
	lore_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(lore_panel)

	var lore_scroll := ScrollContainer.new()
	lore_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lore_panel.add_child(lore_scroll)

	_lore_label = Label.new()
	_lore_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lore_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lore_scroll.add_child(_lore_label)

	# Star requirements section
	var req_header := Label.new()
	req_header.text = "Star Requirements"
	req_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(req_header)

	_requirements_box = VBoxContainer.new()
	_requirements_box.add_theme_constant_override("separation", 4)
	main_box.add_child(_requirements_box)

	# Buttons
	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)
	main_box.add_child(button_row)

	_back_button = Button.new()
	_back_button.text = "Go Back"
	_back_button.pressed.connect(_on_back_pressed)
	button_row.add_child(_back_button)

	_play_button = Button.new()
	_play_button.text = "Play"
	_play_button.pressed.connect(_on_play_pressed)
	button_row.add_child(_play_button)

func show_level(level_id: String, difficulty: String) -> void:
	_level_id = level_id
	_difficulty = difficulty
	visible = true

	# Set title
	var level_name := CampaignManager.get_level_name(level_id)
	_title_label.text = level_name

	# Set difficulty label
	var diff_label := get_node_or_null("PanelContainer/VBoxContainer/DifficultyLabel") as Label
	if diff_label != null:
		diff_label.text = "Difficulty: %s" % difficulty.capitalize()

	# Set lore
	var level_data := CampaignManager.get_level_data(level_id)
	var lore: String = str(level_data.get("lore", "No information available about this mission."))
	_lore_label.text = lore

	# Set star requirements
	_update_requirements()

func _update_requirements() -> void:
	for child in _requirements_box.get_children():
		child.queue_free()

	var thresholds := CampaignManager.get_star_thresholds(_level_id, _difficulty)
	if thresholds.is_empty():
		var no_req := Label.new()
		no_req.text = "No star requirements defined"
		_requirements_box.add_child(no_req)
		return

	# Star 1: Complete the level
	var star1 := Label.new()
	star1.text = "★ Complete the level"
	_requirements_box.add_child(star1)

	# Star 2: Time threshold
	var time_threshold: float = thresholds.get("time", 0.0)
	if time_threshold > 0:
		var minutes: int = int(time_threshold) / 60
		var seconds: int = int(time_threshold) % 60
		var star2 := Label.new()
		star2.text = "★ Complete in under %d:%02d" % [minutes, seconds]
		_requirements_box.add_child(star2)

	# Star 2 alt: Base HP threshold
	var hp_threshold: float = thresholds.get("base_hp_percent", 0.0)
	if hp_threshold > 0:
		var star2hp := Label.new()
		star2hp.text = "   OR keep base HP above %d%%" % int(hp_threshold)
		star2hp.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		_requirements_box.add_child(star2hp)

	# Star 3: Units lost threshold
	var units_threshold: int = thresholds.get("units_lost", 0)
	if units_threshold > 0:
		var star3 := Label.new()
		star3.text = "★ Lose fewer than %d units" % units_threshold
		_requirements_box.add_child(star3)

func _on_play_pressed() -> void:
	visible = false
	play_pressed.emit(_level_id, _difficulty)

func _on_back_pressed() -> void:
	visible = false
	back_pressed.emit()

func hide_ui() -> void:
	visible = false
