class_name MinionAvatar
extends MovingAvatar

func init(data):
	.init(data)
	$Light2D.enabled = !should_disable_light()
	if should_change_color():
		$Icon.texture = preload("res://sprites/godot_favicon_red.png")
