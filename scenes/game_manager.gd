extends Node2D

var level : Node2D
@onready var player_prefab := preload("res://scenes/game/player/player.tscn")
@onready var level_item_prefab := preload("res://scenes/menu/level_item.tscn")

@export var progress := -1
@export var master_vol := 0.5:
	set(value):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)
		master_vol = value

@export var sfx_vol := 1.0:
	set(value):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Sfx"), value)
		sfx_vol = value

@export var music_vol := 1.0:
	set(value):
		AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Music"), value)
		music_vol = value
@export var level_count := 2 # todo figure out a way to not hardcode this

func load_level(level_id: int) -> void:
	if !ResourceLoader.exists("res://scenes/levels/%s.tscn" % level_id, "PackedScene"):
		push_error("Can't load level %s - no such scene exists" % level_id)
		return
	if level:
		level.queue_free()
	await get_tree().process_frame # i have no idea what these awaits accomplish but their absence makes the player spawn weird
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

func transition() -> void:
	$CanvasLayer/TransitionAnimator.play("transition")

func side_transition(is_ltr:=false) -> void:
	$CanvasLayer/TransitionSidewaysAnim.play("transition-rtl", -1, -1 if is_ltr else 1, is_ltr)

func _ready() -> void:
	var config := ConfigFile.new()
	var err := config.load("user://save.cfg")
	if err:
		progress = 0
		config.set_value("settings", "master", 0.5)
		config.set_value("settings", "sfx", 1.0)
		config.set_value("settings", "music", 1.0)
		config.set_value("for_the_curious_user", "a_message", "just *try* to edit this data manually, i DARE you")
		config.set_value("for_the_curious_user", "jk_nothings_gonna_happen", "it's your save do whatever you want ¯\\_(ツ)_/¯")
		config.save("user://save.cfg")
	else:
		progress = config.get_value("completion", "progress", 0)
		master_vol = config.get_value("settings", "master", 0.5)
		sfx_vol = config.get_value("settings", "sfx", 1.0)
		music_vol = config.get_value("settings", "music", 1.0)
	$CanvasLayer/MainMenu/ContinueButton.text = "Continue" if progress else "Play"
	$CanvasLayer/MainMenu/LevelsButton.visible = progress > 0

	for n_level:int in range(level_count):
		var level_item := level_item_prefab.instantiate()
		$CanvasLayer/MainMenu/Levels/ScrollContainer/GridContainer.add_child(level_item)
		level_item.level_id = n_level
		level_item.state = 1 if n_level == progress else 0 if n_level < progress else 2
		level_item.connect("level_selected", load_level_fancy)

func load_level_fancy(level_id: int) -> void:
	side_transition()
	await get_tree().create_timer(0.48).timeout
	$CanvasLayer/MainMenu.visible = false
	load_level(level_id)

func _on_continue_button_pressed() -> void:
	if progress >= 0:
		load_level_fancy(progress)

func _on_levels_button_pressed() -> void:
	if $CanvasLayer/MainMenu/Levels.visible:
		$CanvasLayer/MainMenu/LevelsAnimator.play_backwards("reveal")
	else:
		$CanvasLayer/MainMenu/LevelsAnimator.play("reveal")
