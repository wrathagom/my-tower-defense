extends UnitBase

func _init() -> void:
	speed = 120.0
	max_hp = 6
	attack_range = 140.0
	attack_damage = 1
	attack_cooldown = 1.0
	projectile_speed = 220.0
	jitter_radius = 10.0
	projectile_scene = "res://scenes/StoneProjectile.tscn"

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.6, 0.6, 0.7))
	_draw_health_bar(26.0, 4.0, Vector2(-13.0, -22.0))
