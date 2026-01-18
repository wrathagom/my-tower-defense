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

	main._iron_label = Label.new()
	main._iron_label.text = "Iron: 0 / 0"
	top_center.add_child(main._iron_label)

	main._unit_label = Label.new()
	main._unit_label.text = "Units: 0 / 0"
	top_center.add_child(main._unit_label)
	var menu_button: Button = Button.new()
	menu_button.text = "Menu"
	menu_button.pressed.connect(main._on_menu_pressed)
	top_right.add_child(menu_button)

	main._build_label = Label.new()
	main._build_label.text = "Build: "
	main._base_label = null

	main._upgrade_button = null

	# Stats Panel (left side, below the existing panel)
	main._stats_panel = PanelContainer.new()
	main._stats_panel.position = Vector2(16, 200)
	main._stats_panel.size = Vector2(220, 220)
	main._hud_root.add_child(main._stats_panel)

	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)
	main._stats_panel.add_child(stats_vbox)

	main._stats_base_level_label = Label.new()
	main._stats_base_level_label.text = "Base Level: 1"
	stats_vbox.add_child(main._stats_base_level_label)

	main._stats_timer_label = Label.new()
	main._stats_timer_label.text = "Time: 0:00"
	stats_vbox.add_child(main._stats_timer_label)

	var stats_separator1: HSeparator = HSeparator.new()
	stats_vbox.add_child(stats_separator1)

	main._stats_units_label = Label.new()
	main._stats_units_label.text = "Units: 0 alive / 0 spawned"
	stats_vbox.add_child(main._stats_units_label)

	main._stats_enemies_label = Label.new()
	main._stats_enemies_label.text = "Enemies Killed: 0"
	stats_vbox.add_child(main._stats_enemies_label)

	var stats_separator2: HSeparator = HSeparator.new()
	stats_vbox.add_child(stats_separator2)

	var stars_header: Label = Label.new()
	stars_header.text = "Star Progress:"
	stats_vbox.add_child(stars_header)

	main._stats_stars_box = VBoxContainer.new()
	main._stats_stars_box.add_theme_constant_override("separation", 2)
	stats_vbox.add_child(main._stats_stars_box)

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

	main._upgrade_modal = PanelContainer.new()
	main._upgrade_modal.visible = false
	main._upgrade_modal.size = Vector2(360, 220)
	main._upgrade_modal.anchor_left = 0.5
	main._upgrade_modal.anchor_top = 0.5
	main._upgrade_modal.anchor_right = 0.5
	main._upgrade_modal.anchor_bottom = 0.5
	main._upgrade_modal.offset_left = -180
	main._upgrade_modal.offset_top = -110
	main._upgrade_modal.offset_right = 180
	main._upgrade_modal.offset_bottom = 110
	main._hud_root.add_child(main._upgrade_modal)

	var upgrade_box: VBoxContainer = VBoxContainer.new()
	upgrade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_box.add_theme_constant_override("separation", 8)
	main._upgrade_modal.add_child(upgrade_box)

	main._upgrade_modal_title = Label.new()
	main._upgrade_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main._upgrade_modal_title.text = "Upgrade"
	upgrade_box.add_child(main._upgrade_modal_title)

	main._upgrade_modal_level = Label.new()
	main._upgrade_modal_level.text = "Level: 1 / 1"
	upgrade_box.add_child(main._upgrade_modal_level)

	main._upgrade_modal_cost = Label.new()
	main._upgrade_modal_cost.text = "Cost: -"
	upgrade_box.add_child(main._upgrade_modal_cost)

	main._upgrade_modal_unlocks = Label.new()
	main._upgrade_modal_unlocks.text = "Unlocks: -"
	upgrade_box.add_child(main._upgrade_modal_unlocks)

	var upgrade_button_row: HBoxContainer = HBoxContainer.new()
	upgrade_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_button_row.add_theme_constant_override("separation", 8)
	upgrade_box.add_child(upgrade_button_row)

	main._upgrade_modal_button = Button.new()
	main._upgrade_modal_button.text = "Upgrade"
	main._upgrade_modal_button.pressed.connect(main._on_upgrade_modal_pressed)
	upgrade_button_row.add_child(main._upgrade_modal_button)

	main._upgrade_modal_close = Button.new()
	main._upgrade_modal_close.text = "Close"
	main._upgrade_modal_close.pressed.connect(main._on_upgrade_modal_close_pressed)
	upgrade_button_row.add_child(main._upgrade_modal_close)

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
	bottom_panel.offset_top = -160
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

	var category_row: HBoxContainer = HBoxContainer.new()
	category_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(category_row)
	main._build_category_box = HBoxContainer.new()
	main._build_category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main._build_category_box.add_theme_constant_override("separation", 8)
	category_row.add_child(main._build_category_box)

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
	main._splash_panel.size = Vector2(360, 280)
	main._splash_panel.anchor_left = 0.5
	main._splash_panel.anchor_top = 0.5
	main._splash_panel.anchor_right = 0.5
	main._splash_panel.anchor_bottom = 0.5
	main._splash_panel.offset_left = -180
	main._splash_panel.offset_top = -140
	main._splash_panel.offset_right = 180
	main._splash_panel.offset_bottom = 140
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

	# Campaign button
	main._splash_campaign_button = Button.new()
	main._splash_campaign_button.text = "Campaign"
	main._splash_campaign_button.pressed.connect(main._on_campaign_pressed)
	splash_box.add_child(main._splash_campaign_button)

	# Sandbox section
	var sandbox_label: Label = Label.new()
	sandbox_label.text = "Sandbox Mode"
	sandbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_box.add_child(sandbox_label)

	main._splash_sandbox_button = Button.new()
	main._splash_sandbox_button.text = "Play Sandbox"
	main._splash_sandbox_button.pressed.connect(main._on_sandbox_pressed)
	splash_box.add_child(main._splash_sandbox_button)

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

	# Keep play button reference for compatibility
	main._splash_play_button = main._splash_sandbox_button

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

	for resource_id in main._resource_order:
		if not main._resource_defs.has(resource_id):
			continue
		var def: Dictionary = main._resource_defs[resource_id]
		var button: Button = Button.new()
		button.text = str(def.get("label", resource_id))
		button.pressed.connect(main._on_editor_tool_pressed.bind(resource_id))
		resource_row.add_child(button)

	var enemy_row: HBoxContainer = HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 6)
	editor_box.add_child(enemy_row)

	var enemy_tower_button: Button = Button.new()
	enemy_tower_button.text = "Enemy Tower"
	enemy_tower_button.pressed.connect(main._on_editor_tool_pressed.bind("enemy_tower"))
	enemy_row.add_child(enemy_tower_button)

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

	var export_button: Button = Button.new()
	export_button.text = "Export Campaign"
	export_button.pressed.connect(main._on_editor_export_campaign_pressed)
	save_row.add_child(export_button)

	main._editor_status_label = Label.new()
	main._editor_status_label.text = ""
	editor_box.add_child(main._editor_status_label)

	var back_button: Button = Button.new()
	back_button.text = "Back to Menu"
	back_button.pressed.connect(main._on_editor_back_pressed)
	editor_box.add_child(back_button)

	# Level Select UI
	var LevelSelectScript: Script = load("res://scripts/ui/LevelSelectUI.gd")
	main._level_select_ui = LevelSelectScript.new()
	main._level_select_ui.visible = false
	main._level_select_ui.level_preview_requested.connect(main._on_level_preview_requested)
	main._level_select_ui.back_pressed.connect(main._on_level_select_back)
	main._ui_layer.add_child(main._level_select_ui)

	# Level Launch UI (pre-level screen with lore)
	var LevelLaunchScript: Script = load("res://scripts/ui/LevelLaunchUI.gd")
	main._level_launch_ui = LevelLaunchScript.new()
	main._level_launch_ui.visible = false
	main._level_launch_ui.play_pressed.connect(main._on_level_selected)
	main._level_launch_ui.back_pressed.connect(main._on_level_launch_back)
	main._ui_layer.add_child(main._level_launch_ui)

	# Level Complete UI
	var LevelCompleteScript: Script = load("res://scripts/ui/LevelCompleteUI.gd")
	main._level_complete_ui = LevelCompleteScript.new()
	main._level_complete_ui.visible = false
	main._level_complete_ui.retry_pressed.connect(main._on_level_retry)
	main._level_complete_ui.next_level_pressed.connect(main._on_next_level)
	main._level_complete_ui.level_select_pressed.connect(main._on_level_select_from_complete)
	main._level_complete_ui.main_menu_pressed.connect(main._on_main_menu_from_complete)
	main._ui_layer.add_child(main._level_complete_ui)
