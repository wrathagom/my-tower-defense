extends Node2D

@export var cell: Vector2i
@export var cell_size := 64
@export var spawn_interval := 2.0

var _cooldown := 0.0
var _defenders_by_cell: Dictionary = {}

func _ready() -> void:
	add_to_group("grunt_towers")
	position = Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)
	queue_redraw()

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	_spawn_defenders()
	_cooldown = spawn_interval

func _spawn_defenders() -> void:
	var main := get_parent()
	if main == null:
		return
	var offsets := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for offset in offsets:
		var target_cell: Vector2i = cell + offset
		if not main._is_in_bounds(target_cell):
			continue
		if not main.path_cells.has(target_cell):
			continue
		var existing: Node2D = _defenders_by_cell.get(target_cell, null)
		if existing != null and is_instance_valid(existing):
			continue
		var defender := load("res://scripts/Defender.gd").new() as Node
		var world_pos := Vector2(target_cell.x * cell_size + cell_size * 0.5, target_cell.y * cell_size + cell_size * 0.5)
		defender.set("position", world_pos)
		defender.set("path_points", [world_pos])
		main.add_child(defender)
		if defender.has_signal("died"):
			defender.died.connect(_on_defender_died.bind(target_cell))
		_defenders_by_cell[target_cell] = defender

func _on_defender_died(cell_pos: Vector2i) -> void:
	_defenders_by_cell.erase(cell_pos)

func _draw() -> void:
	var size := cell_size * 0.6
	var half := size * 0.5
	var body_color := Color(0.2, 0.7, 0.35)
	var border_color := Color(0.1, 0.35, 0.2)
	var rect := Rect2(-half, -half, size, size)
	draw_rect(rect, body_color, true)
	draw_rect(rect, border_color, false, 2.0)
