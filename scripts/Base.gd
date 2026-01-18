extends Node2D
class_name Base

@export var size := 56.0
@export var is_goal := false
@export var max_hp := 25
var _hp := 0
var _dead := false
var _show_upgrade_indicator := false
var _can_upgrade := false

signal died

func _ready() -> void:
	_hp = max_hp
	queue_redraw()

func take_damage(amount: int) -> void:
	if _dead:
		return
	_hp = max(0, _hp - amount)
	if _hp == 0:
		_dead = true
		died.emit()
	queue_redraw()

func upgrade(add_hp: int) -> void:
	if _dead:
		return
	max_hp += add_hp
	_hp += add_hp
	queue_redraw()

func reset_hp() -> void:
	_dead = false
	_hp = max_hp
	queue_redraw()

func set_upgrade_indicator(show: bool, can_upgrade: bool, _cost_text: String = "") -> void:
	_show_upgrade_indicator = show
	_can_upgrade = can_upgrade
	queue_redraw()

func _draw() -> void:
	var half := size * 0.5
	var body_color := Color(0.3, 0.3, 0.6) if is_goal else Color(0.2, 0.5, 0.2)
	var border_color := body_color.darkened(0.4)
	var rect := Rect2(-half, -half, size, size)
	draw_rect(rect, body_color, true)
	draw_rect(rect, border_color, false, 2.0)
	_draw_health_bar()
	if _show_upgrade_indicator:
		_draw_upgrade_indicator()

func _draw_health_bar() -> void:
	var bar_width := size * 0.8
	var bar_height := 5.0
	var bar_offset := Vector2(-bar_width * 0.5, -size * 0.6)
	var back_color := Color(0.1, 0.1, 0.1, 0.8)
	var fill_color := Color(0.2, 0.9, 0.3, 0.9)
	var ratio := float(_hp) / float(max_hp)
	var back_rect := Rect2(bar_offset, Vector2(bar_width, bar_height))
	var fill_rect := Rect2(bar_offset, Vector2(bar_width * ratio, bar_height))
	draw_rect(back_rect, back_color, true)
	draw_rect(fill_rect, fill_color, true)

func _draw_upgrade_indicator() -> void:
	var arrow_size := size * 0.35
	var offset := Vector2.ZERO
	var color := Color(0.2, 0.9, 0.3, 0.9) if _can_upgrade else Color(0.5, 0.5, 0.5, 0.6)
	var points := PackedVector2Array([
		offset + Vector2(0, -arrow_size * 0.6),
		offset + Vector2(-arrow_size * 0.5, arrow_size * 0.4),
		offset + Vector2(arrow_size * 0.5, arrow_size * 0.4),
	])
	draw_polygon(points, PackedColorArray([color, color, color]))
