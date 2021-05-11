class_name PlayerAvatar
extends SelectableAvatar

var owner_id
var player_info
var executed_on_the_opponents_computer := false

var final_position

#var var2sync = [ "global_position" ]
func pack(for_own_team: bool):
	#var ret = {} #.pack(for_own_team)
	#for key in var2sync:
	#	ret[key] = avatar_owner[key]
	#return ret
	return {
		"global_position": avatar_owner.global_position,
		"positions": [
			[ Lobby.get_server_time_with_interpolation_offset(), avatar_owner.global_position ]
		]
	}

func pack_initials(for_own_team: bool):
	#var ret = pack(for_own_team) #.pack_initials(for_own_team)
	#ret.owner_id = avatar_owner.id
	#return ret
	return {
		"owner_id": avatar_owner.id,
		"global_position": avatar_owner.global_position
	}

func unpack(data):
	.unpack(data)
	final_position = global_position

func init(data):
	unpack(data)
	
	player_info = Game.players[owner_id]
	if Lobby.local_client.id == player_info.id:
		Events.connect("set_target", self, "on_target_set")
		var camera = $"/root/Control/Camera2D" #TODO: fix absolute path
		camera.get_parent().remove_child(camera)
		add_child(camera)
		camera.position = Vector2.ZERO # Vector2(1280, -720)
		#pass
	else:
		set_process_input(false)
		set_process_unhandled_input(false)
		$Light2D.enabled = !should_disable_light()

func on_target_set(target):
	if typeof(target) == TYPE_VECTOR2:
		rpc_id(1, "set_target", target)
	else:
		rpc_id(1, "set_target", target.get_path())

master func set_target(to):
	#TODO: failsafe
	#print(name, " set_target ", to)
	if typeof(to) == TYPE_NODE_PATH:
		var local_avatar = get_node_or_null(to)
		if local_avatar == null:
			to = null
		else:
			to = (local_avatar as Avatar).avatar_owner
	elif typeof(to) == TYPE_VECTOR2:
		pass
	else:
		to = null
	avatar_owner.lock_target(to)

func _input(event: InputEvent):
	if event is InputEventKey and event.scancode == KEY_4 and event.pressed:
		Events.selection_state = Events.SelectionState.Position
		var selected_pos = yield(Events, "selected")
		Events.selection_state = Events.SelectionState.None
		rpc_id(1, "spawn_totem", selected_pos)
		get_tree().set_input_as_handled()
		
master func spawn_totem(pos):
	avatar_owner.spawn_totem(pos)
