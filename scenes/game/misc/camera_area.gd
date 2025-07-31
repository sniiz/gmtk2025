@tool
extends Node2D

@export var shape : Shape2D:
	set(value):
		shape = value
		$Player/CollisionShape2D.shape = value

func _on_player_area_entered(area: Area2D) -> void:
	get_parent().enabled = true
	get_parent().make_current()

func _on_player_area_exited(area: Area2D) -> void:
	get_parent().make_current()
	get_parent().enabled = false
