@tool
extends StaticBody2D

@onready var radius = $Radius
@export var lasso_radius := 150.0:
	set(value):
		lasso_radius = value
		$Radius.radius = value
		$PlayerDetector/CollisionShape2D.shape.radius = value
@export var radius_color := Color("f6d6bd"):
	set(value):
		radius_color = value
		$Radius.modulate = value
@export var max_momentum := 400.0
@export var spin_speed := 0.2:
	set(value):
		$Radius.turn_speed = value
		spin_speed = value


var player : CharacterBody2D
var is_moused := false
var is_inside := false
var is_grappled := false

func _process(delta: float) -> void:
	if !player:
		player = get_tree().get_first_node_in_group("player")
		return
	if !is_grappled and is_moused and is_inside and Input.is_action_pressed("leftclick"):
		player.set_grappled(true, get_path())
		is_grappled = true
		if is_moused:
			$AnimationPlayer.play_backwards("scale")
	elif is_grappled and Input.is_action_just_released("leftclick"):
		player.set_grappled(false)
		is_grappled = false
		if is_moused:
			$AnimationPlayer.play("scale")

func _on_mouse_entered() -> void:
	is_moused = true
	if !is_grappled: $AnimationPlayer.play("scale")

func _on_mouse_exited() -> void:
	is_moused = false
	if !is_grappled: $AnimationPlayer.play_backwards("scale")

func _on_player_detector_area_entered(area: Area2D) -> void:
	radius.self_modulate = Color("ffffffff")
	is_inside = true

func _on_player_detector_area_exited(area: Area2D) -> void:
	radius.self_modulate = Color("ffffff66")
	is_inside = false
