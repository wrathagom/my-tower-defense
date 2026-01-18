extends "res://scripts/UnitBase.gd"

func _init() -> void:
	speed = 0.0
	max_hp = 6
	attack_range = 22.0
	attack_damage = 1
	attack_cooldown = 0.7
	jitter_radius = 3.0
	group_name = "allies"
	target_group = "enemies"

func _ready() -> void:
	if path_points.is_empty():
		path_points = [position]
	super._ready()

func _move_along_path(_delta: float) -> void:
	return

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(0.2, 0.8, 0.3))
	_draw_health_bar(26.0, 4.0, Vector2(-13.0, -22.0))
