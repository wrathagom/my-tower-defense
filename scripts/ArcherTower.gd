extends "res://scripts/Tower.gd"

func _init() -> void:
	attack_range = 220.0
	fire_rate = 1.2
	damage = 1
	bullet_speed = 420.0
	projectile_scene = "res://scenes/ArrowProjectile.tscn"
	projectile_color = Color(0.95, 0.85, 0.25)
	body_color = Color(0.35, 0.6, 0.25)
	border_color = Color(0.18, 0.32, 0.12)
	arc_color = Color(0.4, 0.7, 0.3, 0.15)
