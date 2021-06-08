class_name MovingAvatar
extends AutoattackingAvatar

var movement_speed := 0.0 setget set_movement_speed
func set_movement_speed(to):
	emit_stat("movement_speed", to)
	movement_speed = to
