extends Node2D

@export var speed := 140.0
@export var max_hp := 6
@export var attack_range := 18.0
@export var attack_damage := 1
@export var attack_cooldown := 0.7
@export var jitter_radius := 10.0
var path_points: Array[Vector2] = []
var _path_index := 0
var _hp := 0
var _cooldown := 0.0
var _jitter := Vector2.ZERO
var _path_position := Vector2.ZERO

signal reached_goal
signal died

func _ready() -> void:
	_hp = max_hp
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_jitter = Vector2(rng.randf_range(-jitter_radius, jitter_radius), rng.randf_range(-jitter_radius, jitter_radius))
	add_to_group("allies")
	if path_points.is_empty():
		queue_free()
		return
	_path_position = path_points[0]
	position = _path_position + _jitter

func _process(delta: float) -> void:
	if _try_attack(delta):
		return
	if path_points.is_empty():
		return
	if _path_index >= path_points.size():
		reached_goal.emit()
		return

	var target := path_points[_path_index]
	var to_target := target - _path_position
	var distance := to_target.length()
	if distance < 2.0:
		_path_index += 1
		return

	var step := speed * delta
	if step >= distance:
		_path_position = target
		_path_index += 1
	else:
		_path_position += to_target.normalized() * step
	position = _path_position + _jitter

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		died.emit()
		queue_free()
	queue_redraw()

func _try_attack(delta: float) -> bool:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return true

	var target := _find_target()
	if target == null:
		return false

	target.take_damage(attack_damage)
	_cooldown = attack_cooldown
	return true

func _find_target() -> Node2D:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var node := enemy as Node2D
		if node == null:
			continue
		if position.distance_to(node.position) <= attack_range:
			return node
	return null

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.2, 0.6, 1.0))
	_draw_health_bar()

func _draw_health_bar() -> void:
	var bar_width := 26.0
	var bar_height := 4.0
	var bar_offset := Vector2(-bar_width * 0.5, -22.0)
	var back_color := Color(0.1, 0.1, 0.1, 0.8)
	var fill_color := Color(0.2, 0.9, 0.3, 0.9)
	var ratio := float(_hp) / float(max_hp)
	var back_rect := Rect2(bar_offset, Vector2(bar_width, bar_height))
	var fill_rect := Rect2(bar_offset, Vector2(bar_width * ratio, bar_height))
	draw_rect(back_rect, back_color, true)
	draw_rect(fill_rect, fill_color, true)
