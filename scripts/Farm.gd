extends Node2D

@export var cell: Vector2i
@export var cell_size := 64
@export var food_per_tick := 1
@export var tick_seconds := 2.0

signal food_produced(amount: int)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	position = Vector2(cell.x * cell_size, cell.y * cell_size)
	var timer := Timer.new()
	timer.wait_time = tick_seconds
	timer.autostart = true
	timer.timeout.connect(_on_tick)
	add_child(timer)
	queue_redraw()

func _on_tick() -> void:
	food_produced.emit(food_per_tick)

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(cell_size * 2, cell_size * 2))
	draw_rect(rect, Color(0.6, 0.7, 0.3), true)
	draw_rect(rect, Color(0.25, 0.35, 0.1), false, 2.0)
