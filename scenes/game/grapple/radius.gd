@tool
extends Node2D

@export var dash_count = 32
@export var radius = 150.0:
	set(value):
		radius = value
@export var turn_speed := 0.2
var turn_offset := 0.0
const dash_gap_ratio = 0.7

func _draw():
	var angle_per_dash = (2.0 * PI) / dash_count
	for i in dash_count:
		var angle_start = i * angle_per_dash + turn_offset
		var angle_end = angle_start + angle_per_dash * (1.0 - dash_gap_ratio)

		var start = Vector2(cos(angle_start), sin(angle_start)) * radius
		var end = Vector2(cos(angle_end), sin(angle_end)) * radius
		draw_line(start, end, Color.WHITE, 1.0)

func _process(delta: float) -> void:
	turn_offset = fmod(turn_offset + turn_speed * delta, PI)
	queue_redraw()
