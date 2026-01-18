extends Node2D

@export var cell: Vector2i
@export var cell_size := 64
@export var attack_range := 160.0
@export var fire_rate := 1.0
@export var damage := 1
@export var bullet_speed := 320.0
@export var projectile_scene := "res://scenes/Bullet.tscn"
@export var projectile_color := Color(0.2, 0.6, 1.0)
@export var body_color := Color(0.2, 0.8, 0.3)
@export var border_color := Color(0.1, 0.4, 0.15)
@export var arc_color := Color(0.2, 0.8, 0.3, 0.15)

var _cooldown := 0.0

func _ready() -> void:
	position = Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return

	var target := _find_target()
	if target == null:
		return

	_spawn_bullet(target)
	_cooldown = 1.0 / fire_rate

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

func _spawn_bullet(target: Node2D) -> void:
	var bullet: Node2D = load(projectile_scene).instantiate() as Node2D
	bullet.position = position
	bullet.target = target
	bullet.speed = bullet_speed
	bullet.damage = damage
	bullet.draw_color = projectile_color
	get_parent().add_child(bullet)

func _draw() -> void:
	var size := cell_size * 0.6
	var half := size * 0.5
	var rect := Rect2(-half, -half, size, size)
	draw_rect(rect, body_color, true)
	draw_rect(rect, border_color, false, 2.0)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, arc_color, 2.0)
