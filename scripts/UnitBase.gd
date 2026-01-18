extends Node2D
class_name UnitBase

@export var speed: float = 120.0
@export var max_hp: int = 6
@export var attack_range: float = 18.0
@export var attack_damage: int = 1
@export var attack_cooldown: float = 0.7
@export var jitter_radius: float = 10.0
@export var stop_on_attack: bool = true
@export var group_name: String = "allies"
@export var target_group: String = "enemies"
@export var projectile_scene: String = ""
@export var projectile_speed: float = 220.0

# Campaign multipliers (applied in _ready)
var hp_multiplier: float = 1.0
var damage_multiplier: float = 1.0

var path_points: Array[Vector2] = []
var _path_index := 0
var _hp := 0
var _cooldown := 0.0
var _jitter := Vector2.ZERO
var _path_position := Vector2.ZERO

signal reached_goal
signal died

func _ready() -> void:
	# Apply multipliers
	max_hp = int(ceil(float(max_hp) * hp_multiplier))
	attack_damage = int(ceil(float(attack_damage) * damage_multiplier))
	_hp = max_hp
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	_jitter = Vector2(rng.randf_range(-jitter_radius, jitter_radius), rng.randf_range(-jitter_radius, jitter_radius))
	if group_name != "":
		add_to_group(group_name)
	if path_points.is_empty():
		queue_free()
		return
	_path_position = path_points[0]
	position = _path_position + _jitter

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_update_behavior(delta)

func _update_behavior(delta: float) -> void:
	var target := _find_target()
	if target != null:
		_try_attack(delta, target)
		if stop_on_attack:
			return
	_move_along_path(delta)

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

func _find_target() -> Node2D:
	var closest: Node2D = null
	var closest_dist := attack_range
	for node in get_tree().get_nodes_in_group(target_group):
		var target := node as Node2D
		if target == null:
			continue
		var dist := position.distance_to(target.position)
		if dist <= closest_dist:
			closest = target
			closest_dist = dist
	return closest

func _try_attack(delta: float, target: Node2D) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	_attack_target(target)
	_cooldown = attack_cooldown

func _attack_target(target: Node2D) -> void:
	if projectile_scene != "":
		_spawn_projectile(target)
		return
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

func _spawn_projectile(target: Node2D) -> void:
	var projectile: Node2D = load(projectile_scene).instantiate() as Node2D
	projectile.position = position
	projectile.set("target", target)
	projectile.set("speed", projectile_speed)
	projectile.set("damage", attack_damage)
	get_parent().add_child(projectile)

func take_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		died.emit()
		queue_free()
	queue_redraw()

func _draw_health_bar(bar_width: float, bar_height: float, bar_offset: Vector2) -> void:
	var back_color := Color(0.1, 0.1, 0.1, 0.8)
	var fill_color := Color(0.2, 0.9, 0.3, 0.9)
	var ratio := float(_hp) / float(max_hp)
	var back_rect := Rect2(bar_offset, Vector2(bar_width, bar_height))
	var fill_rect := Rect2(bar_offset, Vector2(bar_width * ratio, bar_height))
	draw_rect(back_rect, back_color, true)
	draw_rect(fill_rect, fill_color, true)
