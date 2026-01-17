extends "res://scripts/Tower.gd"

func _ready() -> void:
	add_to_group("enemy_towers")
	super._ready()

func _find_target() -> Node2D:
	var closest: Node2D = null
	var closest_dist := attack_range
	for ally in get_tree().get_nodes_in_group("allies"):
		var node := ally as Node2D
		if node == null:
			continue
		var dist := position.distance_to(node.position)
		if dist <= closest_dist:
			closest = node
			closest_dist = dist
	return closest

func _spawn_bullet(target: Node2D) -> void:
	var bullet := preload("res://scenes/Bullet.tscn").instantiate()
	bullet.position = position
	bullet.target = target
	bullet.speed = bullet_speed
	bullet.damage = damage
	bullet.draw_color = Color(1.0, 0.3, 0.3)
	get_parent().add_child(bullet)

func _draw() -> void:
	var size := cell_size * 0.6
	var half := size * 0.5
	var body_color := Color(0.9, 0.2, 0.2)
	var border_color := Color(0.4, 0.1, 0.1)
	var rect := Rect2(-half, -half, size, size)
	draw_rect(rect, body_color, true)
	draw_rect(rect, border_color, false, 2.0)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 64, Color(0.9, 0.2, 0.2, 0.15), 2.0)
