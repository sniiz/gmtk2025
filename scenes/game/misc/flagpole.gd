extends StaticBody2D

func _ready() -> void:
	$AnimatedSprite2D.play("default")

func emit() -> void:
	if OS.get_name() == "Web":
		$CPUParticles2D.emitting = true
	else:
		$GPUParticles2D.emitting = true
