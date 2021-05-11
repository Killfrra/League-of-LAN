class_name Avatar
extends Node2D

var avatar_owner

func pack(for_own_team: bool):
	return {}

func unpack(dict):
	for key in dict:
		self[key] = dict[key]

func pack_initials(for_own_team: bool):
	return pack(for_own_team)

func init(initials):
	unpack(initials)

func sync_opponent(opponent_team):
	var data = pack(false)
	for player in Game.lists[opponent_team].values():
		rpc_id(player.id, "unhide", data)
		
puppetsync func unhide(data):
	#print(name, " show ", data)
	#yield(get_tree().create_timer(0.5), "timeout")
	unpack(data)
	visible = true

func unsync_opponent(opponent_team):
	for player in Game.lists[opponent_team].values():
		rpc_id(player.id, "hide")

puppetsync func hide():
	#print(name, " hide")
	#yield(get_tree().create_timer(0.5), "timeout")
	visible = false

func sync_set(key, value, only_for_teammates := false):
	for client in Game.clients.values():
		if avatar_owner.should_sync_to_client(client):
			rpc_id(client.id, "set_remote", key, value)

func sync_set_unreliable(key, value, only_for_teammates := false):
	for client in Game.clients.values():
		if avatar_owner.should_sync_to_client(client):
			rpc_unreliable_id(client.id, "set_remote", key, value)

puppetsync func set_remote(key, value):
	#print(name, " set_remote ", key, " ", value)
	#yield(get_tree().create_timer(0.5), "timeout")
	self[key] = value

func destroy():
	
	assert(Lobby.local_client.id == 1)
	
	avatar_owner.set_physics_process(false) # чтобы пули не наносили урон дважды
	
	for client in Game.clients.values():
		if client.id != 1 && (avatar_owner.spawned_on_team_computers[client.team] || client.team == avatar_owner.sender.team || client.team == Types.Team.Spectators):
			rpc_id(client.id, "destroy_remote")
	
	avatar_owner.queue_free()
	destroy_remote() #queue_free()

puppetsync func destroy_remote():
	yield(get_tree().create_timer(0.2), "timeout")
	queue_free()
	
var positions := []

puppetsync func interpolate_postition(server_time, to):
	if name.begins_with("Bullet"):
		print(server_time, ' ', to)
	positions.append([server_time, to])

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
			if alpha < 0 || alpha > 1:
				print(name, ' ', alpha, ' ', time_passed, ' ', time_diff_between_frames, ' ', render_time, ' ', positions)
			global_position = positions[0][1].linear_interpolate(positions[1][1], clamp(alpha, 0, 1))
