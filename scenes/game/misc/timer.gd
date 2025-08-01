extends CanvasLayer

@export var active := false:
	set(value):
		active = value
		$FadeInOut.play("activate")
		$Label.visible = true
@export var time_msec := 0.0:
	set(value):
		time_msec = value
		$Label.text = fmt_date(time_msec) + ((
			"\nPB " + fmt_date(pb)
		) if pb > 0.0 else "")
@export var pb := -1.0

func fmt_date(msec:float) -> String:
	var total_sec := msec / 1000
	var minutes := int(total_sec / 60)
	var seconds := int(fmod(total_sec, 60))
	var milliseconds := int(fmod(msec, 1000))
	return "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

func new_pb() -> void:
	$Label.text = "NEW PB! %s" % fmt_date(time_msec)

func _process(delta: float) -> void:
	if !active: return
	time_msec += delta * 1000.0
