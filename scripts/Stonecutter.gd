extends Node2D

@export var cell_size := 64
@export var stone_per_tick := 1
@export var tick_seconds := 2.0

signal stone_produced(amount: int)

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = tick_seconds
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)
	queue_redraw()

func _on_tick() -> void:
	stone_produced.emit(stone_per_tick)

func _draw() -> void:
	var size := cell_size * 0.6
	var half := size * 0.5
	var rect := Rect2(-half, -half, size, size)
	draw_rect(rect, Color(0.45, 0.45, 0.55), true)
	draw_rect(rect, Color(0.2, 0.2, 0.25), false, 2.0)
