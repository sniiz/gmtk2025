extends Node2D

@export var segment_count := 20
@export var rope_stiffness := 15
@export var gravity := Vector2(0, 300)

var points := []
var prev_points := []
var rope_length := 100.0

var grapple_target : Node2D
var player : CharacterBody2D

var start_pos : Vector2
var end_pos : Vector2

func setup(grapple):
	player = get_tree().get_first_node_in_group("player")
	grapple_target = grapple
	start_pos = player.global_position - Vector2(0, 11)
	end_pos = grapple.global_position
	rope_length = grapple.lasso_radius - 15.0

	points.clear()
	prev_points.clear()
	for i in range(segment_count):
		var p = start_pos.lerp(end_pos, float(i) / (segment_count - 1))
		points.append(p)
		prev_points.append(p)

func _process(delta):
	if points.size() < 2: return
	start_pos = player.global_position - Vector2(0, 11)
	end_pos = grapple_target.global_position

	for i in range(1, segment_count-2):
		var velocity = points[i] - prev_points[i]
		prev_points[i] = points[i]
		points[i] += velocity + gravity * delta * delta

	for _blank in rope_stiffness:
		points[0] = start_pos
		points[-1] = end_pos
		for i in range(points.size() - 1):
			var a = points[i]
			var b = points[i + 1]
			var delta_p = b - a
			var dist = delta_p.length()
			var diff = (dist - rope_length / segment_count) / dist
			var offset = delta_p * 0.5 * diff
			if i != 0:
				points[i] += offset
			if i + 1 != points.size() - 1:
				points[i + 1] -= offset

	$Line2D.clear_points()
	for p in points:
		$Line2D.add_point(to_local(p))
	$Line2D.visible = true
