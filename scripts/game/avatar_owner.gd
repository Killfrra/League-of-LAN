class_name AvatarOwner
extends Hiding

export(PackedScene) var avatar_prefab
var avatar
var spawned_on_team_computers := [ true, false, false ]

func _ready():
	
	# server only
	#TODO: move to avatar_spawner
	
	avatar = avatar_prefab.instance()
	avatar.avatar_owner = self
	avatar.visible = should_sync_to_client(Lobby.local_client)
	#avatar.name = AvatarSpawner.get_unique_name()
	#get_tree().get_root()
	$"/root/Control/Avatars".add_child(avatar, true) #TODO: fix absolute path
	
	var initials = avatar.pack_initials(true)
	for client in Game.lists[team].values():
		spawn_avatar_remotely_id(client.id, initials)
	spawned_on_team_computers[team] = true
	
	if team != Types.Team.Spectators:
		for client in Game.spectators.values():
			spawn_avatar_remotely_id(client.id, initials)
		spawned_on_team_computers[Types.Team.Spectators] = true

func spawn_avatar_remotely_id(id, initials):
	if id != 1:
		AvatarSpawner.rpc_id(id, "spawn_avatar_remotely", avatar_prefab.resource_path, avatar.name, initials)
	else: # already spawned on server
		avatar.init(initials) # so just init
		avatar.visible = true

func sync_opponent(opponent_team):
	if not spawned_on_team_computers[opponent_team]:
		spawned_on_team_computers[opponent_team] = true
		
		var initials = avatar.pack_initials(false)
		for player in Game.lists[opponent_team].values():
			spawn_avatar_remotely_id(player.id, initials)
	else:
		avatar.sync_opponent(opponent_team)

func unsync_opponent(opponent_team):
	avatar.unsync_opponent(opponent_team)

func sync_set(key, value, only_for_teammates := false):
	self[key] = value
	avatar.sync_set(key, value, only_for_teammates)

func sync_set_unreliable(key, value, only_for_teammates := false):
	self[key] = value
	avatar.sync_set_unreliable(key, value, only_for_teammates)

func update_position():
	for client in Game.clients.values():
		if should_sync_to_client(client):
			#yield(get_tree().create_timer(randf() * 0.1), "timeout")
			avatar.rpc_unreliable_id(client.id, "interpolate_postition", OS.get_ticks_usec(), global_position)
