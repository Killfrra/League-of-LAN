class_name Ground
extends Area2D

"""
func _ready():
	connect("mouse_entered", self, "on_mouse_entered")
	connect("mouse_exited", self, "on_mouse_exited")

func on_mouse_entered():
	print("mouse entered ", name)

func on_mouse_exited():
	print("mouse exited ", name)
"""

func _input_event(viewport: Object, event: InputEvent, shape_idx: int):
	
	if Events.is_left_mouse_keyup(event): #&& !get_tree().is_input_handled():
		Events.mouse_click_made = true
		Events.mouse_buttton_flags |= Events.button2bit(BUTTON_LEFT)
		Events.click_pos = get_global_mouse_position()
