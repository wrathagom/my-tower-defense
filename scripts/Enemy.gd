extends Node2D

@export var speed := 120.0
@export var max_hp := 5
@export var attack_range := 18.0
@export var attack_damage := 1
@export var attack_cooldown := 0.8
var path_points: Array[Vector2] = []
var _path_index := 0
var _hp := 0
var _cooldown := 0.0

signal reached_goal

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemies")
	if path_points.is_empty():
		queue_free()
		return
	position = path_points[0]

func _process(delta: float) -> void:
	if _try_attack(delta):
		return
	if path_points.is_empty():
		return
	if _path_index >= path_points.size():
		reached_goal.emit()
		return

	var target := path_points[_path_index]
	var to_target := target - position
	var distance := to_target.length()
	if distance < 2.0:
		_path_index += 1
		return

	var step := speed * delta
	if step >= distance:
		position = target
		_path_index += 1
	else:
		position += to_target.normalized() * step

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
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
	for ally in get_tree().get_nodes_in_group("allies"):
		var node := ally as Node2D
		if node == null:
			continue
		if position.distance_to(node.position) <= attack_range:
			return node
	return null

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.9, 0.2, 0.2))
	_draw_health_bar()

func _draw_health_bar() -> void:
	var bar_width := 28.0
	var bar_height := 4.0
	var bar_offset := Vector2(-bar_width * 0.5, -26.0)
	var back_color := Color(0.1, 0.1, 0.1, 0.8)
	var fill_color := Color(0.2, 0.9, 0.3, 0.9)
	var ratio := float(_hp) / float(max_hp)
	var back_rect := Rect2(bar_offset, Vector2(bar_width, bar_height))
	var fill_rect := Rect2(bar_offset, Vector2(bar_width * ratio, bar_height))
	draw_rect(back_rect, back_color, true)
	draw_rect(fill_rect, fill_color, true)
