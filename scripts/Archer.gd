extends UnitBase

func _init() -> void:
	speed = 150.0
	max_hp = 3
	attack_range = 200.0
	attack_damage = 1
	attack_cooldown = 0.9
	projectile_speed = 260.0
	jitter_radius = 10.0
	projectile_scene = "res://scenes/ArrowProjectile.tscn"

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.85, 0.85, 0.55))
	_draw_health_bar(26.0, 4.0, Vector2(-13.0, -22.0))
