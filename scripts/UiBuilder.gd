extends Node
class_name UiBuilder

func build(main: Node) -> void:
	main._ui_layer = CanvasLayer.new()
	main.add_child(main._ui_layer)

	main._hud_root = Control.new()
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
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 24)
	top_panel.add_child(top_row)

	main._wood_label = Label.new()
	main._wood_label.text = "Wood: 0 / 0"
	top_row.add_child(main._wood_label)

	main._food_label = Label.new()
	main._food_label.text = "Food: 0 / 0"
	top_row.add_child(main._food_label)

	main._stone_label = Label.new()
	main._stone_label.text = "Stone: 0 / 0"
	top_row.add_child(main._stone_label)

	main._unit_label = Label.new()
	main._unit_label.text = "Units: 0 / 0"
	top_row.add_child(main._unit_label)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(16, 72)
	panel.size = Vector2(320, 420)
	main._hud_root.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	main._build_label = Label.new()
	main._build_label.text = "Build: "

	main._base_label = Label.new()
	main._base_label.text = main._base_label_text()
	vbox.add_child(main._base_label)

	var title: Label = Label.new()
	title.text = "Path Generator"
	vbox.add_child(title)

	var straight_label: Label = Label.new()
	straight_label.text = "Straightness"
	vbox.add_child(straight_label)

	main._slider_straightness = HSlider.new()
	main._slider_straightness.min_value = 0.0
	main._slider_straightness.max_value = 1.0
	main._slider_straightness.step = 0.05
	main._slider_straightness.value = main.path_straightness
	main._slider_straightness.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main._slider_straightness.value_changed.connect(main._on_straightness_changed)
	vbox.add_child(main._slider_straightness)

	var vertical_label: Label = Label.new()
	vertical_label.text = "Max Vertical Step"
	vbox.add_child(vertical_label)

	main._slider_vertical = HSlider.new()
	main._slider_vertical.min_value = 1.0
	main._slider_vertical.max_value = 12.0
	main._slider_vertical.step = 1.0
	main._slider_vertical.value = float(main.path_max_vertical_step)
	main._slider_vertical.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main._slider_vertical.value_changed.connect(main._on_vertical_step_changed)
	vbox.add_child(main._slider_vertical)

	var length_label: Label = Label.new()
	length_label.text = "Length Multiplier"
	vbox.add_child(length_label)

	main._slider_length = HSlider.new()
	main._slider_length.min_value = 1.0
	main._slider_length.max_value = 3.0
	main._slider_length.step = 0.1
	main._slider_length.value = main.path_length_multiplier
	main._slider_length.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main._slider_length.value_changed.connect(main._on_length_changed)
	vbox.add_child(main._slider_length)

	main._reset_button = Button.new()
	main._reset_button.text = "Reset (Regen Path)"
	main._reset_button.pressed.connect(main._on_reset_pressed)
	vbox.add_child(main._reset_button)

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

	main._splash_exit_button = Button.new()
	main._splash_exit_button.text = "Exit"
	main._splash_exit_button.pressed.connect(main._on_exit_pressed)
	splash_box.add_child(main._splash_exit_button)
