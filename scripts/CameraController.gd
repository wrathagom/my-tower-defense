class_name CameraController
extends Node

const GameWorld = preload("res://scripts/state/GameWorld.gd")

var _main: Node
var _world: GameWorld
var _camera: Camera2D
var _camera_zoom := 1.0
var _camera_target := Vector2.ZERO

func setup(main_node: Node, world: GameWorld) -> void:
	_main = main_node
	_world = world
	_setup_camera()

func _setup_camera() -> void:
	if _main == null or _world == null:
		return
	_camera = Camera2D.new()
	var grid := _world.grid
	_camera_target = Vector2(grid.grid_width * grid.cell_size * 0.5, grid.grid_height * grid.cell_size * 0.5)
	_camera.position = _camera_target
	_main.add_child(_camera)
	_camera.make_current()
	_update_camera_zoom()
	_main.get_viewport().size_changed.connect(_update_camera_zoom)

func _update_camera_zoom() -> void:
	if _world == null or _camera == null:
		return
	var viewport_size: Vector2 = _main.get_viewport_rect().size
	var grid := _world.grid
	var grid_width: int = grid.grid_width
	var grid_height: int = grid.grid_height
	var cell_size: int = grid.cell_size
	var world_size: Vector2 = Vector2(grid_width * cell_size, grid_height * cell_size)
	if world_size.x <= 0 or world_size.y <= 0:
		return
	var zoom_scale: float = minf(viewport_size.x / world_size.x, viewport_size.y / world_size.y)
	if zoom_scale <= 0.0:
		return
	_camera_zoom = clampf(zoom_scale, 0.15, 1.5)
	_camera.zoom = Vector2(_camera_zoom, _camera_zoom)

func handle_zoom_input(event: InputEventMouseButton) -> bool:
	if _camera == null:
		return false
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_camera_zoom = clampf(_camera_zoom * 1.1, 0.15, 2.5)
		_camera.zoom = Vector2(_camera_zoom, _camera_zoom)
		return true
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_camera_zoom = clampf(_camera_zoom / 1.1, 0.15, 2.5)
		_camera.zoom = Vector2(_camera_zoom, _camera_zoom)
		return true
	return false

func update(delta: float, skip_if_typing: bool = false) -> void:
	if _camera == null:
		return
	if skip_if_typing and _main != null:
		var focus := _main.get_viewport().gui_get_focus_owner()
		if focus is LineEdit:
			return
	var speed := 600.0
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0
	if input != Vector2.ZERO:
		_camera_target += input.normalized() * speed * delta
	_camera.position = _camera_target

func get_camera() -> Camera2D:
	return _camera

func get_zoom() -> float:
	return _camera_zoom
