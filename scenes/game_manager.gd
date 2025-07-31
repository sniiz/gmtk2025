extends Node2D

var level : Node2D
@onready var player_prefab := preload("res://scenes/game/player/player.tscn")

func load_level(level_id: int) -> void:
	if !ResourceLoader.exists("res://scenes/levels/%s.tscn" % level_id, "PackedScene"):
		push_error("Can't load level %s - no such scene exists" % level_id)
		return
	if level:
		level.queue_free()
	await get_tree().process_frame
	level = load("res://scenes/levels/%s.tscn" % level_id).instantiate()
	add_child(level)
	var spawner := get_tree().get_first_node_in_group("player_spawner")
	var player_pos := Vector2.ZERO
	if !spawner:
		push_warning("Player spawner not found, spawning at 0,0 instead")
	else:
		player_pos = spawner.global_position
	await get_tree().process_frame
	var player := player_prefab.instantiate()
	level.add_child(player)
	await get_tree().process_frame
	player.global_position = player_pos

func _ready() -> void:
	load_level(0)
