extends Node
class_name UiBuilder

func build(main: Node) -> void:
	main._ui_layer = CanvasLayer.new()
	main.add_child(main._ui_layer)

	main._hud_root = Control.new()
	main._hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main._hud_root.anchor_left = 0.0
	main._hud_root.anchor_right = 1.0
	main._hud_root.anchor_top = 0.0
	main._hud_root.anchor_bottom = 1.0
	main._ui_layer.add_child(main._hud_root)

	var top_panel: PanelContainer = PanelContainer.new()
	top_panel.anchor_left = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 16
	top_panel.offset_right = -16
	top_panel.offset_top = 12
	top_panel.offset_bottom = 56
	main._hud_root.add_child(top_panel)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.add_theme_constant_override("separation", 24)
	top_panel.add_child(top_row)

	var top_left: HBoxContainer = HBoxContainer.new()
	top_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_left.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.add_child(top_left)
	main._speed_button = Button.new()
	main._speed_button.text = "Speed x1"
	main._speed_button.pressed.connect(main._on_speed_pressed)
	top_left.add_child(main._speed_button)

	var top_center: HBoxContainer = HBoxContainer.new()
	top_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top_center.alignment = BoxContainer.ALIGNMENT_CENTER
	top_center.add_theme_constant_override("separation", 24)
	top_row.add_child(top_center)

	var top_right: HBoxContainer = HBoxContainer.new()
	top_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_right.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_child(top_right)

	main._wood_label = Label.new()
	main._wood_label.text = "Wood: 0 / 0"
	top_center.add_child(main._wood_label)

	main._food_label = Label.new()
	main._food_label.text = "Food: 0 / 0"
	top_center.add_child(main._food_label)

	main._stone_label = Label.new()
	main._stone_label.text = "Stone: 0 / 0"
	top_center.add_child(main._stone_label)

	main._unit_label = Label.new()
	main._unit_label.text = "Units: 0 / 0"
	top_center.add_child(main._unit_label)
	var menu_button: Button = Button.new()
	menu_button.text = "Menu"
	menu_button.pressed.connect(main._on_menu_pressed)
	top_right.add_child(menu_button)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(16, 72)
	panel.size = Vector2(240, 120)
	main._hud_root.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	main._build_label = Label.new()
	main._build_label.text = "Build: "

	main._base_label = Label.new()
	main._base_label.text = main._base_label_text()
	vbox.add_child(main._base_label)

	main._upgrade_button = null

	main._game_over_panel = PanelContainer.new()
	main._game_over_panel.visible = false
	main._game_over_panel.size = Vector2(360, 160)
	main._game_over_panel.anchor_left = 0.5
	main._game_over_panel.anchor_top = 0.5
	main._game_over_panel.anchor_right = 0.5
	main._game_over_panel.anchor_bottom = 0.5
	main._game_over_panel.offset_left = -180
	main._game_over_panel.offset_top = -80
	main._game_over_panel.offset_right = 180
	main._game_over_panel.offset_bottom = 80
	main._hud_root.add_child(main._game_over_panel)

	var game_over_box: VBoxContainer = VBoxContainer.new()
	game_over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_over_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_over_box.add_theme_constant_override("separation", 10)
	main._game_over_panel.add_child(game_over_box)

	main._game_over_label = Label.new()
	main._game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main._game_over_label.text = ""
	game_over_box.add_child(main._game_over_label)

	main._game_over_button = Button.new()
	main._game_over_button.text = "Restart"
	main._game_over_button.pressed.connect(main._on_restart_pressed)
	game_over_box.add_child(main._game_over_button)

	main._game_over_exit_button = Button.new()
	main._game_over_exit_button.text = "Exit"
	main._game_over_exit_button.pressed.connect(main._on_exit_pressed)
	game_over_box.add_child(main._game_over_exit_button)

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_top = 0.5
	right_panel.anchor_bottom = 0.5
	right_panel.offset_left = -220
	right_panel.offset_right = -20
	right_panel.offset_top = -60
	right_panel.offset_bottom = 60
	main._hud_root.add_child(right_panel)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_panel.add_child(right_box)
	var spawn_label: Label = Label.new()
	spawn_label.text = "Spawn Units"
	right_box.add_child(spawn_label)
	main._spawn_units_box = VBoxContainer.new()
	main._spawn_units_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main._spawn_units_box.add_theme_constant_override("separation", 6)
	right_box.add_child(main._spawn_units_box)

	var bottom_panel: PanelContainer = PanelContainer.new()
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 16
	bottom_panel.offset_right = -16
	bottom_panel.offset_top = -96
	bottom_panel.offset_bottom = -16
	main._hud_root.add_child(bottom_panel)

	var bottom_box: VBoxContainer = VBoxContainer.new()
	bottom_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_box.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_box)

	var build_header: Label = Label.new()
	build_header.text = "Buildings"
	bottom_box.add_child(build_header)
	bottom_box.add_child(main._build_label)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(button_row)
	main._build_buttons_box = HBoxContainer.new()
	main._build_buttons_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main._build_buttons_box.add_theme_constant_override("separation", 8)
	button_row.add_child(main._build_buttons_box)

	main._pause_panel = PanelContainer.new()
	main._pause_panel.visible = false
	main._pause_panel.size = Vector2(320, 160)
	main._pause_panel.anchor_left = 0.5
	main._pause_panel.anchor_top = 0.5
	main._pause_panel.anchor_right = 0.5
	main._pause_panel.anchor_bottom = 0.5
	main._pause_panel.offset_left = -160
	main._pause_panel.offset_top = -80
	main._pause_panel.offset_right = 160
	main._pause_panel.offset_bottom = 80
	main._ui_layer.add_child(main._pause_panel)

	var pause_box: VBoxContainer = VBoxContainer.new()
	pause_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pause_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_box.add_theme_constant_override("separation", 10)
	main._pause_panel.add_child(pause_box)

	var pause_label: Label = Label.new()
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.text = "Paused"
	pause_box.add_child(pause_label)

	main._pause_resume_button = Button.new()
	main._pause_resume_button.text = "Resume"
	main._pause_resume_button.pressed.connect(main._on_resume_pressed)
	pause_box.add_child(main._pause_resume_button)

	main._pause_exit_button = Button.new()
	main._pause_exit_button.text = "Exit"
	main._pause_exit_button.pressed.connect(main._on_exit_pressed)
	pause_box.add_child(main._pause_exit_button)

	main._splash_panel = PanelContainer.new()
	main._splash_panel.size = Vector2(360, 200)
	main._splash_panel.anchor_left = 0.5
	main._splash_panel.anchor_top = 0.5
	main._splash_panel.anchor_right = 0.5
	main._splash_panel.anchor_bottom = 0.5
	main._splash_panel.offset_left = -180
	main._splash_panel.offset_top = -100
	main._splash_panel.offset_right = 180
	main._splash_panel.offset_bottom = 100
	main._ui_layer.add_child(main._splash_panel)

	var splash_box: VBoxContainer = VBoxContainer.new()
	splash_box.alignment = BoxContainer.ALIGNMENT_CENTER
	splash_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	splash_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splash_box.add_theme_constant_override("separation", 10)
	main._splash_panel.add_child(splash_box)

	var splash_title: Label = Label.new()
	splash_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_title.text = "Tower Defense"
	splash_box.add_child(splash_title)

	main._splash_play_button = Button.new()
	main._splash_play_button.text = "Play"
	main._splash_play_button.pressed.connect(main._on_play_pressed)
	splash_box.add_child(main._splash_play_button)

	main._splash_map_label = Label.new()
	main._splash_map_label.text = "Map"
	splash_box.add_child(main._splash_map_label)

	main._splash_map_select = OptionButton.new()
	main._splash_map_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splash_box.add_child(main._splash_map_select)

	main._splash_create_button = Button.new()
	main._splash_create_button.text = "Create Map"
	main._splash_create_button.pressed.connect(main._on_create_map_pressed)
	splash_box.add_child(main._splash_create_button)

	main._splash_exit_button = Button.new()
	main._splash_exit_button.text = "Exit"
	main._splash_exit_button.pressed.connect(main._on_exit_pressed)
	splash_box.add_child(main._splash_exit_button)

	main._editor_panel = PanelContainer.new()
	main._editor_panel.visible = false
	main._editor_panel.size = Vector2(300, 320)
	main._editor_panel.anchor_left = 0.0
	main._editor_panel.anchor_top = 0.5
	main._editor_panel.anchor_right = 0.0
	main._editor_panel.anchor_bottom = 0.5
	main._editor_panel.offset_left = 16
	main._editor_panel.offset_top = -160
	main._editor_panel.offset_right = 316
	main._editor_panel.offset_bottom = 160
	main._ui_layer.add_child(main._editor_panel)

	var editor_box: VBoxContainer = VBoxContainer.new()
	editor_box.add_theme_constant_override("separation", 8)
	main._editor_panel.add_child(editor_box)

	var editor_title: Label = Label.new()
	editor_title.text = "Map Editor"
	editor_box.add_child(editor_title)

	main._editor_tool_label = Label.new()
	main._editor_tool_label.text = "Tool: Path"
	editor_box.add_child(main._editor_tool_label)

	var tool_row: HBoxContainer = HBoxContainer.new()
	tool_row.add_theme_constant_override("separation", 6)
	editor_box.add_child(tool_row)

	var path_button: Button = Button.new()
	path_button.text = "Path"
	path_button.pressed.connect(main._on_editor_tool_pressed.bind("path"))
	tool_row.add_child(path_button)

	var base_start_button: Button = Button.new()
	base_start_button.text = "Player Base"
	base_start_button.pressed.connect(main._on_editor_tool_pressed.bind("base_start"))
	tool_row.add_child(base_start_button)

	var base_end_button: Button = Button.new()
	base_end_button.text = "Enemy Base"
	base_end_button.pressed.connect(main._on_editor_tool_pressed.bind("base_end"))
	tool_row.add_child(base_end_button)

	var resource_row: HBoxContainer = HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 6)
	editor_box.add_child(resource_row)

	var tree_button: Button = Button.new()
	tree_button.text = "Tree"
	tree_button.pressed.connect(main._on_editor_tool_pressed.bind("tree"))
	resource_row.add_child(tree_button)

	var stone_button: Button = Button.new()
	stone_button.text = "Stone"
	stone_button.pressed.connect(main._on_editor_tool_pressed.bind("stone"))
	resource_row.add_child(stone_button)

	var erase_button: Button = Button.new()
	erase_button.text = "Erase"
	erase_button.pressed.connect(main._on_editor_tool_pressed.bind("erase"))
	resource_row.add_child(erase_button)

	var name_label: Label = Label.new()
	name_label.text = "Map Name"
	editor_box.add_child(name_label)

	main._editor_name_input = LineEdit.new()
	main._editor_name_input.placeholder_text = "example_map"
	editor_box.add_child(main._editor_name_input)

	var save_row: HBoxContainer = HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 6)
	editor_box.add_child(save_row)

	var save_button: Button = Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(main._on_editor_save_pressed)
	save_row.add_child(save_button)

	var load_button: Button = Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(main._on_editor_load_pressed)
	save_row.add_child(load_button)

	main._editor_status_label = Label.new()
	main._editor_status_label.text = ""
	editor_box.add_child(main._editor_status_label)

	var back_button: Button = Button.new()
	back_button.text = "Back to Menu"
	back_button.pressed.connect(main._on_editor_back_pressed)
	editor_box.add_child(back_button)
