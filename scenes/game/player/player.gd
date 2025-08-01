extends CharacterBody2D

@export var gravity := 1000.0
@export var grounded_accel := 10.0
@export var grounded_stop := 20.0
@export var midair_accel := 4.0
@export var jump_impulse := 300.0
@export var max_speed := 180.0

var coyote := false
var last_floor := false
var jumping := false
var buffered_jump := false
var last_input := 1.0

var is_grappled := false
var grapple : StaticBody2D
var rope_length := 0.0
var is_flying_after_grapple := false
var flight_direction := 0.0
var rope_sim : Node2D
var grapple_max_momentum : float
var is_immobile := false
var is_dead := false

var has_moved := false

@onready var rope_prefab := preload("res://scenes/game/player/rope.tscn")

func reset() -> void:
	#get_tree().reload_current_scene()
	var game := get_parent().get_parent()
	game.transition()
	await get_tree().create_timer(0.46).timeout
	game.load_level(get_parent().level_index)

func set_grappled(state: bool, grapple_path=null) -> void:
	if is_immobile: return
	is_grappled = state
	if is_grappled:
		grapple = get_node(grapple_path)
		#rope_length = (global_position - grapple.global_position).length() # while grappled, the player can't stay further than rope_length away from the grapple, although no new force should push them to that distance
		rope_length = grapple.lasso_radius
		if rope_sim:
			rope_sim.queue_free()
		rope_sim = rope_prefab.instantiate()
		add_sibling(rope_sim)
		rope_sim.setup(grapple)
		$AnimatedSprite2D.play("spin")
	else:
		$AnimatedSprite2D.play("default")
		is_flying_after_grapple = true
		flight_direction = sign(velocity.x)
		if rope_sim:
			rope_sim.queue_free()

func _process(delta: float) -> void:
	if is_dead: return
	var input := Input.get_axis("left", "right") if !is_immobile else 0.0
	if input != 0.0:
		last_input = input
		if !has_moved:
			has_moved = true
			get_tree().get_first_node_in_group("timer").active = true

	$Sprite.scale.x = last_input
	$AnimatedSprite2D.scale.x = last_input

	if !is_grappled:
		if is_flying_after_grapple and ((sign(input) == flight_direction and abs(velocity.x) > max_speed) or !input):
			pass
		else:
			velocity.x = lerp(velocity.x, input * max_speed, ((grounded_accel if input != 0.0 else grounded_stop) if is_on_floor() else midair_accel * (3.0 if is_grappled else 1.0)) * delta)
	if abs(velocity.x) < 1 and !is_grappled and is_on_floor():
		$Sprite.visible = true
		$AnimatedSprite2D.visible = false
	else:
		$Sprite.visible = false
		$AnimatedSprite2D.visible = true
		$AnimatedSprite2D.speed_scale = abs(velocity.x) / max_speed
		if is_grappled:
			if (!$AnimatedSprite2D.is_playing() || $AnimatedSprite2D.animation != "spin"):
				$AnimatedSprite2D.play("spin")
		elif !is_on_floor():
			if velocity.y < 0:
				if (!$AnimatedSprite2D.is_playing() || $AnimatedSprite2D.animation != "jump"):
					$AnimatedSprite2D.play("jump")
			else:
				if (!$AnimatedSprite2D.is_playing() || $AnimatedSprite2D.animation != "fall"):
					$AnimatedSprite2D.play("fall")
		else:
			if (!$AnimatedSprite2D.is_playing() || $AnimatedSprite2D.animation != "default"):
				$AnimatedSprite2D.play("default")

	if Input.is_action_just_pressed("jump"):
		buffered_jump = true
		$JumpBufferTimer.start()
		if !has_moved:
			has_moved = true
			get_tree().get_first_node_in_group("timer").active = true

	if buffered_jump and (is_on_floor() || coyote) and !is_immobile:
		velocity.y = -jump_impulse
		jumping = true
		buffered_jump = false
		$JumpBufferTimer.stop()

	if !is_on_floor() and last_floor and !jumping:
		coyote = true
		$CoyoteTimer.start()

	if is_grappled and is_instance_valid(grapple):
		var to_grapple = global_position - grapple.global_position
		var distance = to_grapple.length()
		var angle = rad_to_deg(to_grapple.angle())
		angle = ((360 + angle) if angle < 0 else angle) + 90
		angle = (360 - angle) if last_input < 0 else angle
		angle = ((360 + angle) if angle < 0 else angle)
		$AnimatedSprite2D.frame = floor(fmod(angle, 360) / 45.0)
		if distance > rope_length:
			var dir = to_grapple.normalized()
			global_position = grapple.global_position + dir * rope_length

			var tangent = Vector2(-dir.y, dir.x)
			var tangential_velocity = tangent.dot(velocity)

			velocity = (tangent * tangential_velocity).limit_length(grapple.max_momentum)
		if input != 0.0:
			var tangent = Vector2(-to_grapple.normalized().y, to_grapple.normalized().x)
			velocity += tangent * -input * 300.0 * delta
	if !is_on_floor():
		velocity.y += gravity * delta
	else:
		is_flying_after_grapple = false

	if position.y >= 300.0:
		reset()

	last_floor = is_on_floor()

	move_and_slide()

func _on_coyote_timer_timeout() -> void:
	coyote = false

func _on_jump_buffer_timer_timeout() -> void:
	buffered_jump = false

func _on_hurtbox_body_entered(body: Node2D) -> void:
	is_dead = true
	$AnimationPlayer.play("death")
	await get_tree().create_timer(0.5).timeout
	reset()

func _on_area_2d_body_entered(body: Node2D) -> void:
	is_immobile = true
	get_tree().get_first_node_in_group("timer").active = false
	get_tree().get_first_node_in_group("flagpole").emit()
	$LevelEndTimer.start()
	var config := ConfigFile.new()
	var err := config.load("user://save.cfg")
	if err:
		print(err)
		OS.alert("Something went EXTREMELY wrong when loading your save file. Sorry!", "Oh dear")
		get_tree().reload_current_scene()
		return
	var saved_progress : int = config.get_value("completion", "progress", 0)
	var saved_pb : float = config.get_value("pb", str(get_parent().level_index), -1.0)
	saved_pb = INF if saved_pb == -1.0 else saved_pb
	config.set_value("pb", str(get_parent().level_index), min(get_tree().get_first_node_in_group("timer").time_msec, saved_pb))
	if saved_pb > get_tree().get_first_node_in_group("timer").time_msec:
		get_tree().get_first_node_in_group("timer").new_pb()
	config.set_value("completion", "progress", max(saved_progress, get_parent().next_level_index))
	config.save("user://save.cfg")

func death_particles() -> void:
	if OS.get_name() == "Web":
		$CPUParticles2D.emitting = true
	else:
		$GPUParticles2D.emitting = true

func _on_level_end_timer_timeout() -> void:
	get_parent().get_parent().side_transition()
	await get_tree().create_timer(0.47).timeout
	get_parent().get_parent().load_level(get_parent().next_level_index)
