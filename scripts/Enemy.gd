extends UnitBase

func _init() -> void:
	speed = 120.0
	max_hp = 5
	attack_range = 18.0
	attack_damage = 1
	attack_cooldown = 0.8
	jitter_radius = 10.0
	group_name = "enemies"
	target_group = "allies"

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.9, 0.2, 0.2))
	_draw_health_bar(28.0, 4.0, Vector2(-14.0, -26.0))
