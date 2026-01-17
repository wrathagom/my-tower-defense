extends Node2D
class_name ProjectileBase

@export var speed: float = 220.0
@export var damage: int = 1
@export var hit_radius: float = 8.0
@export var draw_radius: float = 3.0
@export var draw_color: Color = Color(0.8, 0.8, 0.8)

var target: Node2D

func _ready() -> void:
	add_to_group("projectiles")

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var to_target := target.position - position
	var distance := to_target.length()
	if distance <= hit_radius:
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
		return
	position += to_target.normalized() * speed * delta
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, draw_radius, draw_color)
