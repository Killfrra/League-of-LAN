#global Events
extends Node

signal set_target(to)
signal selected(pos_or_entity)
signal show_info(about)

enum SelectionState { None, Position, Entity }
var selection_state = SelectionState.None

var mouse_click_made := false
var mouse_buttton_flags := 0
var clicked_objects := []
var click_pos: Vector2

func is_left_mouse_keyup(event: InputEvent):
	return is_mouse_keyup(event) and event.button_index == BUTTON_LEFT

func is_mouse_keyup(event: InputEvent):
	return (event is InputEventMouseButton and event.pressed and (event.button_index == BUTTON_LEFT || event.button_index == BUTTON_RIGHT))

func button2bit(button_index):
	return 1 << (button_index - 1)

func process_event(obj, event):
	if Events.is_mouse_keyup(event):
		mouse_click_made = true
		mouse_buttton_flags |= button2bit(event.button_index)
		clicked_objects.append(obj)
		click_pos = obj.get_global_mouse_position()

func _process(delta):
	if mouse_click_made && mouse_buttton_flags & (button2bit(BUTTON_LEFT) | button2bit(BUTTON_RIGHT)):
		mouse_click_made = false
		var best_target = null
		
		if selection_state == SelectionState.Position:
			best_target = click_pos
		else:
			if selection_state == SelectionState.None:
				best_target = click_pos
			var min_dist := -1.0
			for obj in clicked_objects:
				#TODO: check the sound
				if !is_instance_valid(obj) || (mouse_buttton_flags & button2bit(BUTTON_LEFT) && obj.team == Lobby.local_client.team):
					continue
				var dist = obj.global_position.distance_squared_to(click_pos)
				if min_dist < 0 || dist < min_dist:
					min_dist = dist
					best_target = obj
			
		clicked_objects.resize(0)
		if best_target:
			if mouse_buttton_flags & button2bit(BUTTON_LEFT):
				if selection_state == SelectionState.None:
					emit_signal("set_target", best_target)
				else:
					emit_signal("selected", best_target)
			else:
				emit_signal("show_info", best_target)
				
			#selection_state = SelectionState.None

		mouse_buttton_flags = 0
