#global Events
extends Node2D

signal set_target(to)
signal selected(pos_or_entity)

enum SelectionState { None, Position, Entity }
var selection_state = SelectionState.None

var mouse_click_made := false
var clicked_objects := []
var click_pos: Vector2

func is_left_mouse_keyup(event: InputEvent):
	return (event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed)

var ignore_ground := 0

func register_click(target):
	mouse_click_made = true
	clicked_objects.append(target)

func _process(delta):
	if mouse_click_made:
		mouse_click_made = false
		var best_target = null
		if selection_state == SelectionState.Position:
			best_target = click_pos
		else:
			if selection_state == SelectionState.None:
				best_target = click_pos
			var min_dist := -1.0
			for obj in clicked_objects:
				if !is_instance_valid(obj) || obj.owner_team == Lobby.local_client.team:
					continue
				var dist = obj.global_position.distance_squared_to(click_pos)
				if min_dist < 0 || dist < min_dist:
					min_dist = dist
					best_target = obj
			
		clicked_objects.resize(0)
		if best_target:
			emit_signal("set_target" if selection_state == SelectionState.None else "selected", best_target)
			#selection_state = SelectionState.None
