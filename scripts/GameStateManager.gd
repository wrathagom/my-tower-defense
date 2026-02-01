class_name GameStateManager
extends Node

signal state_changed(new_state: String)
signal game_over_triggered(is_player_base: bool)

const UiController = preload("res://scripts/UiController.gd")

var _main: Node
var _game_over := false
var _splash_active := true
var _paused := false
var _fast_forward := false

var _ui: UiController
var _enemy_timer: Timer

func setup(main_node: Node) -> void:
	_main = main_node
	_sync_ui_refs()

func _sync_ui_refs() -> void:
	if _main == null:
		return
	_ui = _main._ui_controller
	_enemy_timer = _main._enemy_timer

func is_game_over() -> bool:
	return _game_over

func is_splash_active() -> bool:
	return _splash_active

func is_paused() -> bool:
	return _paused

func is_fast_forward() -> bool:
	return _fast_forward

func set_splash_active(active: bool) -> void:
	_splash_active = active
	if _ui != null:
		_ui.set_hud_visible(not active)
		_ui.set_splash_visible(active)
		_ui.set_game_over_visible(false)
	if _enemy_timer != null:
		if active:
			_enemy_timer.stop()
		else:
			_enemy_timer.start()
	if active:
		set_fast_forward(false)
		set_paused(false)
		if _main != null and _main._upgrade_manager != null:
			_main._upgrade_manager.set_upgrade_modal_visible(false)
	state_changed.emit("splash" if active else "playing")

func set_paused(active: bool) -> void:
	if _game_over:
		return
	_paused = active
	if _ui != null:
		_ui.set_pause_visible(active)
	if _main != null:
		_main.get_tree().paused = active
	if _enemy_timer != null:
		if active:
			_enemy_timer.stop()
		else:
			_enemy_timer.start()
	if active and _main != null and _main._upgrade_manager != null:
		_main._upgrade_manager.set_upgrade_modal_visible(false)
	state_changed.emit("paused" if active else "playing")

func set_fast_forward(active: bool) -> void:
	_fast_forward = active
	Engine.time_scale = 2.0 if active else 1.0
	_update_speed_button_text()

func _update_speed_button_text() -> void:
	if _ui != null:
		_ui.set_speed_button_text(_fast_forward)

func on_game_over(is_player_base: bool) -> void:
	if _game_over:
		return
	_game_over = true
	if _enemy_timer != null:
		_enemy_timer.stop()
	if _main != null and _main._upgrade_manager != null:
		_main._upgrade_manager.set_upgrade_modal_visible(false)
	if _main != null:
		var spawn_buttons: Dictionary = _main._spawn_buttons
		for button in spawn_buttons.values():
			if button is Button:
				button.disabled = true
				continue
			if button is Dictionary:
				for entry in button.values():
					var node := entry as Button
					if node != null:
						node.disabled = true
	if _ui != null:
		_ui.set_game_over_visible(true)
		_ui.set_game_over_text("You Lose" if is_player_base else "You Win")
	game_over_triggered.emit(is_player_base)
	state_changed.emit("game_over")

func reset() -> void:
	_game_over = false
	_splash_active = false
	_paused = false
	set_fast_forward(false)
	if _ui != null:
		_ui.set_game_over_visible(false)
