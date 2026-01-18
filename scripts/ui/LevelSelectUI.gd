extends Control
class_name LevelSelectUI

signal level_selected(level_id: String, difficulty: String)
signal level_preview_requested(level_id: String, difficulty: String)
signal back_pressed()

var _level_list: VBoxContainer
var _difficulty_panel: PanelContainer
var _difficulty_box: VBoxContainer
var _level_name_label: Label
var _stars_label: Label
var _difficulty_buttons: Dictionary = {}
var _selected_level_id: String = ""
var _back_button: Button
var _reset_button: Button
var _confirm_panel: PanelContainer

func _ready() -> void:
	_build_ui()
	_refresh_levels()

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
	main_panel.offset_left = -300
	main_panel.offset_right = 300
	main_panel.offset_top = -250
	main_panel.offset_bottom = 250
	add_child(main_panel)

	var main_box := VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 12)
	main_panel.add_child(main_box)

	var title := Label.new()
	title.text = "Select Level"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(title)

	var total_stars := Label.new()
	total_stars.name = "TotalStars"
	total_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_box.add_child(total_stars)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_box.add_child(content)

	# Level list panel
	var level_panel := PanelContainer.new()
	level_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(level_panel)

	var level_scroll := ScrollContainer.new()
	level_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	level_panel.add_child(level_scroll)

	_level_list = VBoxContainer.new()
	_level_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_list.add_theme_constant_override("separation", 4)
	level_scroll.add_child(_level_list)

	# Difficulty panel
	_difficulty_panel = PanelContainer.new()
	_difficulty_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_difficulty_panel.visible = false
	content.add_child(_difficulty_panel)

	_difficulty_box = VBoxContainer.new()
	_difficulty_box.add_theme_constant_override("separation", 8)
	_difficulty_panel.add_child(_difficulty_box)

	_level_name_label = Label.new()
	_level_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_box.add_child(_level_name_label)

	_stars_label = Label.new()
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_box.add_child(_stars_label)

	var diff_label := Label.new()
	diff_label.text = "Difficulty"
	diff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_difficulty_box.add_child(diff_label)

	for diff in CampaignManager.DIFFICULTIES:
		var button := Button.new()
		button.text = diff.capitalize()
		button.pressed.connect(_on_difficulty_selected.bind(diff))
		_difficulty_box.add_child(button)
		_difficulty_buttons[diff] = button

	# Bottom button row
	var bottom_row := HBoxContainer.new()
	bottom_row.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom_row.add_theme_constant_override("separation", 16)
	main_box.add_child(bottom_row)

	_back_button = Button.new()
	_back_button.text = "Back"
	_back_button.pressed.connect(_on_back_pressed)
	bottom_row.add_child(_back_button)

	_reset_button = Button.new()
	_reset_button.text = "Reset Campaign"
	_reset_button.pressed.connect(_on_reset_pressed)
	bottom_row.add_child(_reset_button)

	# Confirmation dialog
	_confirm_panel = PanelContainer.new()
	_confirm_panel.visible = false
	_confirm_panel.anchor_left = 0.5
	_confirm_panel.anchor_right = 0.5
	_confirm_panel.anchor_top = 0.5
	_confirm_panel.anchor_bottom = 0.5
	_confirm_panel.offset_left = -180
	_confirm_panel.offset_right = 180
	_confirm_panel.offset_top = -80
	_confirm_panel.offset_bottom = 80
	add_child(_confirm_panel)

	var confirm_box := VBoxContainer.new()
	confirm_box.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_box.add_theme_constant_override("separation", 12)
	_confirm_panel.add_child(confirm_box)

	var confirm_label := Label.new()
	confirm_label.text = "Reset all campaign progress?"
	confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_box.add_child(confirm_label)

	var confirm_warning := Label.new()
	confirm_warning.text = "This cannot be undone!"
	confirm_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_warning.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	confirm_box.add_child(confirm_warning)

	var confirm_buttons := HBoxContainer.new()
	confirm_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	confirm_buttons.add_theme_constant_override("separation", 16)
	confirm_box.add_child(confirm_buttons)

	var cancel_button := Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_reset_cancel)
	confirm_buttons.add_child(cancel_button)

	var confirm_button := Button.new()
	confirm_button.text = "Reset"
	confirm_button.pressed.connect(_on_reset_confirm)
	confirm_buttons.add_child(confirm_button)

func _refresh_levels() -> void:
	for child in _level_list.get_children():
		child.queue_free()

	var level_ids := CampaignManager.get_level_ids()
	for level_id in level_ids:
		var button := Button.new()
		var level_name := CampaignManager.get_level_name(level_id)
		var unlocked := CampaignManager.is_level_unlocked(level_id)
		var total_stars := 0
		for diff in CampaignManager.DIFFICULTIES:
			total_stars += CampaignManager.get_stars(level_id, diff)

		if unlocked:
			button.text = "%s [%d/9]" % [level_name, total_stars]
		else:
			button.text = "%s [Locked]" % level_name
		button.disabled = not unlocked
		button.pressed.connect(_on_level_selected.bind(level_id))
		_level_list.add_child(button)

	# Update total stars
	var total := CampaignManager.get_total_stars()
	var stars_label := get_node_or_null("PanelContainer/VBoxContainer/TotalStars") as Label
	if stars_label != null:
		stars_label.text = "Total Stars: %d" % total

func _on_level_selected(level_id: String) -> void:
	_selected_level_id = level_id
	_difficulty_panel.visible = true
	_level_name_label.text = CampaignManager.get_level_name(level_id)

	var level_stars := 0
	for diff in CampaignManager.DIFFICULTIES:
		level_stars += CampaignManager.get_stars(level_id, diff)
	_stars_label.text = "Stars: %d / 9" % level_stars

	_update_difficulty_buttons()

func _update_difficulty_buttons() -> void:
	for diff in CampaignManager.DIFFICULTIES:
		var button := _difficulty_buttons.get(diff) as Button
		if button == null:
			continue
		var unlocked := CampaignManager.is_difficulty_unlocked(_selected_level_id, diff)
		var stars := CampaignManager.get_stars(_selected_level_id, diff)
		var star_text := ""
		if stars > 0:
			star_text = " [%d/3]" % stars
		button.text = diff.capitalize() + star_text
		button.disabled = not unlocked

func _on_difficulty_selected(difficulty: String) -> void:
	if _selected_level_id == "" or not CampaignManager.is_difficulty_unlocked(_selected_level_id, difficulty):
		return
	level_preview_requested.emit(_selected_level_id, difficulty)

func _on_back_pressed() -> void:
	back_pressed.emit()

func show_ui() -> void:
	visible = true
	_refresh_levels()
	_difficulty_panel.visible = false
	_selected_level_id = ""

func hide_ui() -> void:
	visible = false
	_confirm_panel.visible = false

func _on_reset_pressed() -> void:
	_confirm_panel.visible = true

func _on_reset_cancel() -> void:
	_confirm_panel.visible = false

func _on_reset_confirm() -> void:
	_confirm_panel.visible = false
	CampaignManager.reset_progress()
	_refresh_levels()
	_difficulty_panel.visible = false
	_selected_level_id = ""
