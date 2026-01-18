extends UnitBase

func _init() -> void:
	speed = 135.0
	max_hp = 8
	attack_range = 18.0
	attack_damage = 2
	attack_cooldown = 0.75
	jitter_radius = 10.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.85, 0.25, 0.25))
	_draw_health_bar(26.0, 4.0, Vector2(-13.0, -22.0))
