extends "res://scripts/Tower.gd"

func _init() -> void:
	attack_range = 160.0
	fire_rate = 1.0
	damage = 1
	bullet_speed = 320.0
	projectile_scene = "res://scenes/Bullet.tscn"
	projectile_color = Color(0.7, 0.7, 0.8)
	body_color = Color(0.45, 0.55, 0.65)
	border_color = Color(0.2, 0.25, 0.3)
	arc_color = Color(0.5, 0.6, 0.7, 0.15)
