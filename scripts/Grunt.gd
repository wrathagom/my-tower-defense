extends UnitBase

func _init() -> void:
	speed = 100.0
	max_hp = 4
	attack_range = 18.0
	attack_damage = 1
	attack_cooldown = 1.0
	jitter_radius = 10.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.2, 0.6, 1.0))
	_draw_health_bar(26.0, 4.0, Vector2(-13.0, -22.0))
