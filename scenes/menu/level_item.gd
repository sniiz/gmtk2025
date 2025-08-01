#@tool
extends PanelContainer

@onready var panel_complete := load("res://scenes/menu/level_item_complete.tres")
@onready var panel_current := load("res://scenes/menu/level_item_current.tres")
@onready var panel_locked := load("res://scenes/menu/level_item_locked.tres")

@export_range(0, 2) var state := 0:
	set(value):
		state = value
		self["theme_override_styles/panel"] = [panel_complete, panel_current, panel_locked][state]
		$CenterContainer/Label.modulate = Color(["08141e", "c3a38a", "816271"][state])
@export var level_id := 0:
	set(value):
		level_id = value
		$CenterContainer/Label.text = str(value + 1)

signal level_selected(id: int)
var mouse_is_in := false

func _on_mouse_entered() -> void:
	mouse_is_in = true
func _on_mouse_exited() -> void:
	mouse_is_in = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("leftclick") and mouse_is_in and visible and state < 2:
		level_selected.emit(level_id)
