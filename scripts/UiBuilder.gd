extends Node
class_name UiBuilder

const UiController = preload("res://scripts/UiController.gd")

func build(main: Node, ui: UiController) -> void:
	main._ui_layer = CanvasLayer.new()
	main.add_child(main._ui_layer)

	ui.hud_root = Control.new()
	ui.hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.hud_root.anchor_left = 0.0
	ui.hud_root.anchor_right = 1.0
	ui.hud_root.anchor_top = 0.0
	ui.hud_root.anchor_bottom = 1.0
	main._ui_layer.add_child(ui.hud_root)

	var top_panel: PanelContainer = PanelContainer.new()
	top_panel.anchor_left = 0.0
	top_panel.anchor_right = 1.0
	top_panel.anchor_top = 0.0
	top_panel.anchor_bottom = 0.0
	top_panel.offset_left = 16
	top_panel.offset_right = -16
	top_panel.offset_top = 12
	top_panel.offset_bottom = 56
	ui.hud_root.add_child(top_panel)

	var top_row: HBoxContainer = HBoxContainer.new()
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.add_theme_constant_override("separation", 24)
	top_panel.add_child(top_row)

	var top_left: HBoxContainer = HBoxContainer.new()
	top_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_left.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.add_child(top_left)
	ui.speed_button = Button.new()
	ui.speed_button.text = "Speed x1"
	ui.speed_button.pressed.connect(main._on_speed_pressed)
	top_left.add_child(ui.speed_button)

	var top_center: HBoxContainer = HBoxContainer.new()
	top_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top_center.alignment = BoxContainer.ALIGNMENT_CENTER
	top_center.add_theme_constant_override("separation", 24)
	top_row.add_child(top_center)

	var top_right: HBoxContainer = HBoxContainer.new()
	top_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_right.alignment = BoxContainer.ALIGNMENT_END
	top_row.add_child(top_right)

	ui.wood_label = Label.new()
	ui.wood_label.text = "Wood: 0 / 0"
	top_center.add_child(ui.wood_label)

	ui.food_label = Label.new()
	ui.food_label.text = "Food: 0 / 0"
	top_center.add_child(ui.food_label)

	ui.stone_label = Label.new()
	ui.stone_label.text = "Stone: 0 / 0"
	top_center.add_child(ui.stone_label)

	ui.iron_label = Label.new()
	ui.iron_label.text = "Iron: 0 / 0"
	top_center.add_child(ui.iron_label)

	ui.unit_label = Label.new()
	ui.unit_label.text = "Units: 0 / 0"
	top_center.add_child(ui.unit_label)
	var menu_button: Button = Button.new()
	menu_button.text = "Menu"
	menu_button.pressed.connect(main._on_menu_pressed)
	top_right.add_child(menu_button)

	ui.build_label = Label.new()
	ui.build_label.text = "Build: "
	ui.build_label.add_theme_font_size_override("font_size", 24)

	main._upgrade_button = null

	# Stats Panel (left side, below the existing panel)
	ui.stats_panel = PanelContainer.new()
	ui.stats_panel.position = Vector2(16, 200)
	ui.stats_panel.size = Vector2(220, 220)
	ui.hud_root.add_child(ui.stats_panel)

	var stats_vbox: VBoxContainer = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)
	ui.stats_panel.add_child(stats_vbox)

	ui.stats_base_level_label = Label.new()
	ui.stats_base_level_label.text = "Base Level: 1"
	stats_vbox.add_child(ui.stats_base_level_label)

	ui.stats_timer_label = Label.new()
	ui.stats_timer_label.text = "Time: 0:00"
	stats_vbox.add_child(ui.stats_timer_label)

	var stats_separator1: HSeparator = HSeparator.new()
	stats_vbox.add_child(stats_separator1)

	ui.stats_units_label = Label.new()
	ui.stats_units_label.text = "Units: 0 alive / 0 spawned"
	stats_vbox.add_child(ui.stats_units_label)

	ui.stats_enemies_label = Label.new()
	ui.stats_enemies_label.text = "Enemies Killed: 0"
	stats_vbox.add_child(ui.stats_enemies_label)

	var stats_separator2: HSeparator = HSeparator.new()
	stats_vbox.add_child(stats_separator2)

	var stars_header: Label = Label.new()
	stars_header.text = "Star Progress:"
	stats_vbox.add_child(stars_header)

	ui.stats_stars_box = VBoxContainer.new()
	ui.stats_stars_box.add_theme_constant_override("separation", 2)
	stats_vbox.add_child(ui.stats_stars_box)

	ui.game_over_panel = PanelContainer.new()
	ui.game_over_panel.visible = false
	ui.game_over_panel.size = Vector2(360, 160)
	ui.game_over_panel.anchor_left = 0.5
	ui.game_over_panel.anchor_top = 0.5
	ui.game_over_panel.anchor_right = 0.5
	ui.game_over_panel.anchor_bottom = 0.5
	ui.game_over_panel.offset_left = -180
	ui.game_over_panel.offset_top = -80
	ui.game_over_panel.offset_right = 180
	ui.game_over_panel.offset_bottom = 80
	ui.hud_root.add_child(ui.game_over_panel)

	var game_over_box: VBoxContainer = VBoxContainer.new()
	game_over_box.alignment = BoxContainer.ALIGNMENT_CENTER
	game_over_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	game_over_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game_over_box.add_theme_constant_override("separation", 10)
	ui.game_over_panel.add_child(game_over_box)

	ui.game_over_label = Label.new()
	ui.game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.game_over_label.text = ""
	game_over_box.add_child(ui.game_over_label)

	ui.game_over_button = Button.new()
	ui.game_over_button.text = "Restart"
	ui.game_over_button.pressed.connect(main._on_restart_pressed)
	game_over_box.add_child(ui.game_over_button)

	ui.game_over_exit_button = Button.new()
	ui.game_over_exit_button.text = "Exit"
	ui.game_over_exit_button.pressed.connect(main._on_exit_pressed)
	game_over_box.add_child(ui.game_over_exit_button)

	ui.upgrade_modal = PanelContainer.new()
	ui.upgrade_modal.visible = false
	ui.upgrade_modal.size = Vector2(360, 220)
	ui.upgrade_modal.anchor_left = 0.5
	ui.upgrade_modal.anchor_top = 0.5
	ui.upgrade_modal.anchor_right = 0.5
	ui.upgrade_modal.anchor_bottom = 0.5
	ui.upgrade_modal.offset_left = -180
	ui.upgrade_modal.offset_top = -110
	ui.upgrade_modal.offset_right = 180
	ui.upgrade_modal.offset_bottom = 110
	ui.hud_root.add_child(ui.upgrade_modal)

	var upgrade_box: VBoxContainer = VBoxContainer.new()
	upgrade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_box.add_theme_constant_override("separation", 8)
	ui.upgrade_modal.add_child(upgrade_box)

	ui.upgrade_modal_title = Label.new()
	ui.upgrade_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.upgrade_modal_title.text = "Upgrade"
	upgrade_box.add_child(ui.upgrade_modal_title)

	ui.upgrade_modal_level = Label.new()
	ui.upgrade_modal_level.text = "Level: 1 / 1"
	upgrade_box.add_child(ui.upgrade_modal_level)

	ui.upgrade_modal_cost = Label.new()
	ui.upgrade_modal_cost.text = "Cost: -"
	upgrade_box.add_child(ui.upgrade_modal_cost)

	ui.upgrade_modal_unlocks = Label.new()
	ui.upgrade_modal_unlocks.text = "Unlocks: -"
	upgrade_box.add_child(ui.upgrade_modal_unlocks)

	var upgrade_button_row: HBoxContainer = HBoxContainer.new()
	upgrade_button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_button_row.add_theme_constant_override("separation", 8)
	upgrade_box.add_child(upgrade_button_row)

	ui.upgrade_modal_button = Button.new()
	ui.upgrade_modal_button.text = "Upgrade"
	ui.upgrade_modal_button.pressed.connect(main._on_upgrade_modal_pressed)
	upgrade_button_row.add_child(ui.upgrade_modal_button)

	ui.upgrade_modal_close = Button.new()
	ui.upgrade_modal_close.text = "Close"
	ui.upgrade_modal_close.pressed.connect(main._on_upgrade_modal_close_pressed)
	upgrade_button_row.add_child(ui.upgrade_modal_close)

	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.anchor_left = 1.0
	right_panel.anchor_right = 1.0
	right_panel.anchor_top = 0.5
	right_panel.anchor_bottom = 0.5
	right_panel.offset_left = -220
	right_panel.offset_right = -20
	right_panel.offset_top = -60
	right_panel.offset_bottom = 60
	ui.hud_root.add_child(right_panel)

	var right_box: VBoxContainer = VBoxContainer.new()
	right_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	right_panel.add_child(right_box)
	var spawn_label: Label = Label.new()
	spawn_label.text = "Spawn Units"
	right_box.add_child(spawn_label)
	ui.spawn_units_box = VBoxContainer.new()
	ui.spawn_units_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.spawn_units_box.add_theme_constant_override("separation", 6)
	right_box.add_child(ui.spawn_units_box)

	var bottom_panel: PanelContainer = PanelContainer.new()
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_top = 1.0
	bottom_panel.anchor_bottom = 1.0
	bottom_panel.offset_left = 16
	bottom_panel.offset_right = -16
	bottom_panel.offset_top = -160
	bottom_panel.offset_bottom = -16
	ui.hud_root.add_child(bottom_panel)

	var bottom_box: VBoxContainer = VBoxContainer.new()
	bottom_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom_box.add_theme_constant_override("separation", 6)
	bottom_panel.add_child(bottom_box)

	var build_header: Label = Label.new()
	build_header.text = "Buildings"
	bottom_box.add_child(build_header)
	bottom_box.add_child(ui.build_label)

	var category_row: HBoxContainer = HBoxContainer.new()
	category_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(category_row)
	ui.build_category_box = HBoxContainer.new()
	ui.build_category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.build_category_box.add_theme_constant_override("separation", 8)
	category_row.add_child(ui.build_category_box)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_theme_constant_override("separation", 8)
	bottom_box.add_child(button_row)
	ui.build_buttons_box = HBoxContainer.new()
	ui.build_buttons_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ui.build_buttons_box.add_theme_constant_override("separation", 8)
	button_row.add_child(ui.build_buttons_box)

	ui.pause_panel = PanelContainer.new()
	ui.pause_panel.visible = false
	ui.pause_panel.size = Vector2(320, 160)
	ui.pause_panel.anchor_left = 0.5
	ui.pause_panel.anchor_top = 0.5
	ui.pause_panel.anchor_right = 0.5
	ui.pause_panel.anchor_bottom = 0.5
	ui.pause_panel.offset_left = -160
	ui.pause_panel.offset_top = -80
	ui.pause_panel.offset_right = 160
	ui.pause_panel.offset_bottom = 80
	main._ui_layer.add_child(ui.pause_panel)

	var pause_box: VBoxContainer = VBoxContainer.new()
	pause_box.alignment = BoxContainer.ALIGNMENT_CENTER
	pause_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pause_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pause_box.add_theme_constant_override("separation", 10)
	ui.pause_panel.add_child(pause_box)

	var pause_label: Label = Label.new()
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.text = "Paused"
	pause_box.add_child(pause_label)

	ui.pause_resume_button = Button.new()
	ui.pause_resume_button.text = "Resume"
	ui.pause_resume_button.pressed.connect(main._on_resume_pressed)
	pause_box.add_child(ui.pause_resume_button)

	ui.pause_exit_button = Button.new()
	ui.pause_exit_button.text = "Exit"
	ui.pause_exit_button.pressed.connect(main._on_exit_pressed)
	pause_box.add_child(ui.pause_exit_button)

	ui.splash_panel = PanelContainer.new()
	ui.splash_panel.size = Vector2(360, 280)
	ui.splash_panel.anchor_left = 0.5
	ui.splash_panel.anchor_top = 0.5
	ui.splash_panel.anchor_right = 0.5
	ui.splash_panel.anchor_bottom = 0.5
	ui.splash_panel.offset_left = -180
	ui.splash_panel.offset_top = -140
	ui.splash_panel.offset_right = 180
	ui.splash_panel.offset_bottom = 140
	main._ui_layer.add_child(ui.splash_panel)

	var splash_box: VBoxContainer = VBoxContainer.new()
	splash_box.alignment = BoxContainer.ALIGNMENT_CENTER
	splash_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	splash_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splash_box.add_theme_constant_override("separation", 10)
	ui.splash_panel.add_child(splash_box)

	var splash_title: Label = Label.new()
	splash_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_title.text = "Tower Defense"
	splash_box.add_child(splash_title)

	# Campaign button
	ui.splash_campaign_button = Button.new()
	ui.splash_campaign_button.text = "Campaign"
	ui.splash_campaign_button.pressed.connect(main._on_campaign_pressed)
	splash_box.add_child(ui.splash_campaign_button)

	# Sandbox section
	var sandbox_label: Label = Label.new()
	sandbox_label.text = "Sandbox Mode"
	sandbox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	splash_box.add_child(sandbox_label)

	ui.splash_sandbox_button = Button.new()
	ui.splash_sandbox_button.text = "Play Sandbox"
	ui.splash_sandbox_button.pressed.connect(main._on_sandbox_pressed)
	splash_box.add_child(ui.splash_sandbox_button)

	ui.splash_map_label = Label.new()
	ui.splash_map_label.text = "Map"
	splash_box.add_child(ui.splash_map_label)

	ui.splash_map_select = OptionButton.new()
	ui.splash_map_select.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	splash_box.add_child(ui.splash_map_select)

	ui.splash_create_button = Button.new()
	ui.splash_create_button.text = "Create Map"
	ui.splash_create_button.pressed.connect(main._on_create_map_pressed)
	splash_box.add_child(ui.splash_create_button)

	ui.splash_exit_button = Button.new()
	ui.splash_exit_button.text = "Exit"
	ui.splash_exit_button.pressed.connect(main._on_exit_pressed)
	splash_box.add_child(ui.splash_exit_button)

	# Keep play button reference for compatibility
	ui.splash_play_button = ui.splash_sandbox_button

	ui.editor_panel = PanelContainer.new()
	ui.editor_panel.visible = false
	ui.editor_panel.size = Vector2(300, 360)
	ui.editor_panel.anchor_left = 0.0
	ui.editor_panel.anchor_top = 0.5
	ui.editor_panel.anchor_right = 0.0
	ui.editor_panel.anchor_bottom = 0.5
	ui.editor_panel.offset_left = 16
	ui.editor_panel.offset_top = -180
	ui.editor_panel.offset_right = 316
	ui.editor_panel.offset_bottom = 180
	main._ui_layer.add_child(ui.editor_panel)

	var editor_box: VBoxContainer = VBoxContainer.new()
	editor_box.add_theme_constant_override("separation", 8)
	ui.editor_panel.add_child(editor_box)

	var editor_title: Label = Label.new()
	editor_title.text = "Map Editor"
	editor_box.add_child(editor_title)

	ui.editor_tool_label = Label.new()
	ui.editor_tool_label.text = "Tool: Path"
	editor_box.add_child(ui.editor_tool_label)

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

	for resource_id in main._world.resources.order:
		if not main._world.resources.defs.has(resource_id):
			continue
		var def: Dictionary = main._world.resources.defs[resource_id]
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

	ui.editor_name_input = LineEdit.new()
	ui.editor_name_input.placeholder_text = "example_map"
	editor_box.add_child(ui.editor_name_input)

	var campaign_label: Label = Label.new()
	campaign_label.text = "Campaign Level"
	editor_box.add_child(campaign_label)

	ui.editor_campaign_select = OptionButton.new()
	editor_box.add_child(ui.editor_campaign_select)

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

	var load_campaign_button: Button = Button.new()
	load_campaign_button.text = "Load Campaign"
	load_campaign_button.pressed.connect(main._on_editor_load_campaign_pressed)
	save_row.add_child(load_campaign_button)

	var export_button: Button = Button.new()
	export_button.text = "Save Campaign"
	export_button.pressed.connect(main._on_editor_export_campaign_pressed)
	save_row.add_child(export_button)

	ui.editor_status_label = Label.new()
	ui.editor_status_label.text = ""
	editor_box.add_child(ui.editor_status_label)

	ui.editor_campaign_panel = PanelContainer.new()
	ui.editor_campaign_panel.visible = false
	ui.editor_campaign_panel.anchor_left = 1.0
	ui.editor_campaign_panel.anchor_top = 0.5
	ui.editor_campaign_panel.anchor_right = 1.0
	ui.editor_campaign_panel.anchor_bottom = 0.5
	ui.editor_campaign_panel.offset_left = -576
	ui.editor_campaign_panel.offset_right = -16
	ui.editor_campaign_panel.offset_top = -310
	ui.editor_campaign_panel.offset_bottom = 310
	main._ui_layer.add_child(ui.editor_campaign_panel)

	var campaign_scroll := ScrollContainer.new()
	campaign_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ui.editor_campaign_panel.add_child(campaign_scroll)

	var campaign_box := VBoxContainer.new()
	campaign_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	campaign_box.add_theme_constant_override("separation", 8)
	campaign_scroll.add_child(campaign_box)

	var campaign_title := Label.new()
	campaign_title.text = "Campaign Level Settings"
	campaign_box.add_child(campaign_title)

	var campaign_name_label: Label = Label.new()
	campaign_name_label.text = "Name"
	campaign_box.add_child(campaign_name_label)
	ui.editor_campaign_name = LineEdit.new()
	campaign_box.add_child(ui.editor_campaign_name)

	var lore_label: Label = Label.new()
	lore_label.text = "Lore"
	campaign_box.add_child(lore_label)
	ui.editor_campaign_lore = TextEdit.new()
	ui.editor_campaign_lore.custom_minimum_size = Vector2(0, 120)
	ui.editor_campaign_lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_box.add_child(ui.editor_campaign_lore)

	var order_row := HBoxContainer.new()
	order_row.add_theme_constant_override("separation", 8)
	campaign_box.add_child(order_row)
	var order_label: Label = Label.new()
	order_label.text = "Campaign Order"
	order_row.add_child(order_label)
	ui.editor_campaign_order = SpinBox.new()
	ui.editor_campaign_order.min_value = 0
	ui.editor_campaign_order.max_value = 999
	ui.editor_campaign_order.step = 1
	order_row.add_child(ui.editor_campaign_order)

	var max_base_row := HBoxContainer.new()
	max_base_row.add_theme_constant_override("separation", 8)
	campaign_box.add_child(max_base_row)
	var max_base_label: Label = Label.new()
	max_base_label.text = "Max Base Level"
	max_base_row.add_child(max_base_label)
	ui.editor_campaign_max_base = SpinBox.new()
	ui.editor_campaign_max_base.min_value = 1
	ui.editor_campaign_max_base.max_value = 10
	ui.editor_campaign_max_base.step = 1
	max_base_row.add_child(ui.editor_campaign_max_base)

	var units_label: Label = Label.new()
	units_label.text = "Available Units (comma-separated)"
	campaign_box.add_child(units_label)
	ui.editor_campaign_units = LineEdit.new()
	campaign_box.add_child(ui.editor_campaign_units)

	var buildings_label: Label = Label.new()
	buildings_label.text = "Available Buildings (comma-separated)"
	campaign_box.add_child(buildings_label)
	ui.editor_campaign_buildings = LineEdit.new()
	campaign_box.add_child(ui.editor_campaign_buildings)

	var challenge_label: Label = Label.new()
	challenge_label.text = "Challenge Modes (comma-separated)"
	campaign_box.add_child(challenge_label)
	ui.editor_campaign_challenge_modes = LineEdit.new()
	campaign_box.add_child(ui.editor_campaign_challenge_modes)

	_add_campaign_difficulty_form(campaign_box, "Easy", ui, "easy")
	_add_campaign_difficulty_form(campaign_box, "Medium", ui, "medium")
	_add_campaign_difficulty_form(campaign_box, "Hard", ui, "hard")

	var campaign_button_row := HBoxContainer.new()
	campaign_button_row.add_theme_constant_override("separation", 8)
	campaign_box.add_child(campaign_button_row)
	var campaign_save_button := Button.new()
	campaign_save_button.text = "Apply & Save"
	campaign_save_button.pressed.connect(main._on_editor_campaign_edit_save_pressed)
	campaign_button_row.add_child(campaign_save_button)
	var campaign_cancel_button := Button.new()
	campaign_cancel_button.text = "Cancel"
	campaign_cancel_button.pressed.connect(main._on_editor_campaign_edit_cancel_pressed)
	campaign_button_row.add_child(campaign_cancel_button)

	var back_button: Button = Button.new()
	back_button.text = "Back to Menu"
	back_button.pressed.connect(main._on_editor_back_pressed)
	editor_box.add_child(back_button)

func build_campaign_ui(main: Node, campaign_controller) -> void:
	var LevelSelectScript: Script = load("res://scripts/ui/LevelSelectUI.gd")
	var level_select_ui = LevelSelectScript.new()
	level_select_ui.visible = false
	main._ui_layer.add_child(level_select_ui)
	campaign_controller.set_level_select_ui(level_select_ui)

	var LevelLaunchScript: Script = load("res://scripts/ui/LevelLaunchUI.gd")
	var level_launch_ui = LevelLaunchScript.new()
	level_launch_ui.visible = false
	main._ui_layer.add_child(level_launch_ui)
	campaign_controller.set_level_launch_ui(level_launch_ui)

	var LevelCompleteScript: Script = load("res://scripts/ui/LevelCompleteUI.gd")
	var level_complete_ui = LevelCompleteScript.new()
	level_complete_ui.visible = false
	main._ui_layer.add_child(level_complete_ui)
	campaign_controller.set_level_complete_ui(level_complete_ui)

func _add_campaign_difficulty_form(parent: VBoxContainer, title: String, ui: UiController, key: String) -> void:
	var section_label := Label.new()
	section_label.text = "%s Difficulty" % title
	parent.add_child(section_label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("separation", 6)
	parent.add_child(grid)

	var spawn := _add_campaign_spinbox(grid, "Spawn Interval", 0.1, 60.0, 0.1)
	var enemy_hp := _add_campaign_spinbox(grid, "Enemy HP Mult", 0.1, 5.0, 0.1)
	var enemy_damage := _add_campaign_spinbox(grid, "Enemy Damage Mult", 0.1, 5.0, 0.1)
	var enemy_base_hp := _add_campaign_spinbox(grid, "Enemy Base HP Mult", 0.1, 5.0, 0.1)
	var res_wood := _add_campaign_spinbox(grid, "Start Wood", 0, 999, 1)
	var res_food := _add_campaign_spinbox(grid, "Start Food", 0, 999, 1)
	var res_stone := _add_campaign_spinbox(grid, "Start Stone", 0, 999, 1)
	var res_iron := _add_campaign_spinbox(grid, "Start Iron", 0, 999, 1)
	var star_time := _add_campaign_spinbox(grid, "Star Time (s)", 0, 9999, 10)
	var star_base_hp := _add_campaign_spinbox(grid, "Star Base HP %", 0, 100, 1)
	var star_units := _add_campaign_spinbox(grid, "Star Units Lost", 0, 9999, 1)

	if key == "easy":
		ui.editor_campaign_easy_spawn = spawn
		ui.editor_campaign_easy_enemy_hp = enemy_hp
		ui.editor_campaign_easy_enemy_damage = enemy_damage
		ui.editor_campaign_easy_enemy_base_hp = enemy_base_hp
		ui.editor_campaign_easy_res_wood = res_wood
		ui.editor_campaign_easy_res_food = res_food
		ui.editor_campaign_easy_res_stone = res_stone
		ui.editor_campaign_easy_res_iron = res_iron
		ui.editor_campaign_easy_star_time = star_time
		ui.editor_campaign_easy_star_base_hp = star_base_hp
		ui.editor_campaign_easy_star_units = star_units
	elif key == "medium":
		ui.editor_campaign_medium_spawn = spawn
		ui.editor_campaign_medium_enemy_hp = enemy_hp
		ui.editor_campaign_medium_enemy_damage = enemy_damage
		ui.editor_campaign_medium_enemy_base_hp = enemy_base_hp
		ui.editor_campaign_medium_res_wood = res_wood
		ui.editor_campaign_medium_res_food = res_food
		ui.editor_campaign_medium_res_stone = res_stone
		ui.editor_campaign_medium_res_iron = res_iron
		ui.editor_campaign_medium_star_time = star_time
		ui.editor_campaign_medium_star_base_hp = star_base_hp
		ui.editor_campaign_medium_star_units = star_units
	elif key == "hard":
		ui.editor_campaign_hard_spawn = spawn
		ui.editor_campaign_hard_enemy_hp = enemy_hp
		ui.editor_campaign_hard_enemy_damage = enemy_damage
		ui.editor_campaign_hard_enemy_base_hp = enemy_base_hp
		ui.editor_campaign_hard_res_wood = res_wood
		ui.editor_campaign_hard_res_food = res_food
		ui.editor_campaign_hard_res_stone = res_stone
		ui.editor_campaign_hard_res_iron = res_iron
		ui.editor_campaign_hard_star_time = star_time
		ui.editor_campaign_hard_star_base_hp = star_base_hp
		ui.editor_campaign_hard_star_units = star_units

func _add_campaign_spinbox(grid: GridContainer, label_text: String, min_value: float, max_value: float, step: float) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	grid.add_child(label)
	var box := SpinBox.new()
	box.min_value = min_value
	box.max_value = max_value
	box.step = step
	grid.add_child(box)
	return box
