class_name Avatar
extends Node2D

var id
var team
var avatar_owner

func unpack(dict):
	for key in dict:
		self[key] = dict[key]

# called by AvatarSpawner
func init(initials):
	unpack(initials)
	positions = [
		[
			Lobby.get_ticks_usec() + Lobby.server_time_offset,
			global_position
		]
	]

# called by AvatarOwner
puppetsync func unhide(data):
	#print(name, " show ", data)
	#yield(get_tree().create_timer(0.5), "timeout")
	unpack(data)
	visible = true

# called by AvatarOwner
puppetsync func hide():
	#print(name, " hide")
	#yield(get_tree().create_timer(0.5), "timeout")
	emit_signal("destroyed") #TODO: new signal? rename?
	visible = false

# called by AvatarOwner
#TODO: isolate variables in dict for security?
#TODO: rename to remote_set
puppetsync func set_remote(key, value):
	#print(name, " set_remote ", key, " ", value)
	#yield(get_tree().create_timer(0.5), "timeout")
	self[key] = value

signal destroyed()
puppetsync func destroy_remote(when):
	var time_diff = when - Lobby.get_server_time_with_interpolation_offset()
	if time_diff > 0:
		yield(get_tree().create_timer(float(time_diff) / float(Lobby.sec_to_server_time_mul)), "timeout")
	emit_signal("destroyed")
	queue_free()
	
var positions := []

puppetsync func interpolate_position(server_time, to):
	positions.append([server_time, to])
	
	#if name.begins_with("Bullet"):
	#	print(server_time, ' ', to)
	#	print(positions)

	#var prev_pos: Vector2
func _process(delta):
	#if prev_pos == global_position && name.begins_with("Bullet"):
	#	print('freeze')
	#prev_pos = global_position
	
	var render_time: int = Lobby.get_server_time_with_interpolation_offset()
	
	if positions.size() > 1 && positions[0][0] < render_time:
		
		while positions.size() > 2 && render_time > positions[1][0]:
			positions.pop_front()
		
		var time_diff_between_frames: int = positions[1][0] - positions[0][0]
		if time_diff_between_frames != 0: #TODO: think about it
			var time_passed: int = render_time - positions[0][0]
			var alpha: float = float(time_passed) / float(time_diff_between_frames)
			#if name.begins_with("Bullet"):
			#	print(alpha)
			#if alpha < 0 || alpha > 1:
			#	print(name, ' ', alpha, ' ', time_passed, ' ', time_diff_between_frames, ' ', render_time, ' ', positions)
			global_position = positions[0][1].linear_interpolate(positions[1][1], clamp(alpha, 0, 1))
