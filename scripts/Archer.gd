extends Node2D

@export var speed := 120.0
@export var max_hp := 6
@export var attack_range := 180.0
@export var attack_damage := 2
@export var attack_cooldown := 0.9
@export var projectile_speed := 260.0
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
	if get_tree().paused:
		return
	if _has_enemy_in_range():
		_try_attack(delta)
		return
	_move_along_path(delta)

func _has_enemy_in_range() -> bool:
	var closest: Node2D = null
	var closest_dist := attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var node := enemy as Node2D
		if node == null:
			continue
		var dist := position.distance_to(node.position)
		if dist <= closest_dist:
			closest = node
			closest_dist = dist
	return closest != null

func _try_attack(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	var target := _find_target()
	if target == null:
		return
	_spawn_projectile(target)
	_cooldown = attack_cooldown

func _find_target() -> Node2D:
	var closest: Node2D = null
	var closest_dist := attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var node := enemy as Node2D
		if node == null:
			continue
		var dist := position.distance_to(node.position)
		if dist <= closest_dist:
			closest = node
			closest_dist = dist
	return closest

func _spawn_projectile(target: Node2D) -> void:
	var projectile := preload("res://scenes/ArrowProjectile.tscn").instantiate()
	projectile.position = position
	projectile.target = target
	projectile.speed = projectile_speed
	projectile.damage = attack_damage
	get_parent().add_child(projectile)

func _move_along_path(delta: float) -> void:
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

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.85, 0.85, 0.55))
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
