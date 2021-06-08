class_name AvatarOwner
extends Node2D

# Hidden

export(Types.Team) var team
var seen_by_teams := [0, 0, 0]
onready var seen_by_num = seen_by_teams[0] + seen_by_teams[1] + seen_by_teams[2]

signal out_of_sight(for_team)
signal in_sight(for_team)

#TODO: move somewhere?
var effects := {}

func on_seen_by(entity):
	assert(entity.team != Types.Team.Spectators)
	seen_by_teams[entity.team] += 1
	seen_by_num += 1
	if seen_by_teams[entity.team] == 1:
		emit_signal("in_sight", entity.team)
		sync_opponent(entity.team)
	#print(name, " seen by ", entity.name, " so nums are ", seen_by_teams)

func on_unseen_by(entity):
	assert(entity.team != Types.Team.Spectators)
	seen_by_teams[entity.team] -= 1
	seen_by_num -= 1
	if seen_by_teams[entity.team] == 0:
		#TODO: fix "method not found" bug
		emit_signal("out_of_sight", entity.team)
		unsync_opponent(entity.team)
	#print(name, " unseen by ", entity.name, " so nums are ", seen_by_teams)

func should_sync_to_client(client):
	return client.team == team || client.team == Types.Team.Spectators || seen_by_teams[client.team] > 0

# AvatarOwner

var id = null #1
export(PackedScene) var avatar_prefab
var avatar
var spawned_on_team_computers := [ true, false, false ]

enum Attrs {
	RELIABLE = 0, # default
	UNRELIABLE = 1,
	CONST = 2,
	VISIBLE_TO_EVERYONE = 4,
	VISIBLE_TO_TEAM_AND_SPEC = 8,
	VISIBLE_TO_OWNER_AND_SPEC = 16,
}

#func merge_dict(target, patch):
#	for key in patch:
#		target[key] = patch[key]
#	return target

var var_attrs
func generate_variable_attributes():
	var_attrs = {
		"id": Attrs.CONST | Attrs.VISIBLE_TO_EVERYONE,
		"team": Attrs.CONST | Attrs.VISIBLE_TO_EVERYONE,
		"global_position": Attrs.CONST | Attrs.VISIBLE_TO_EVERYONE
	}

func _init():
	generate_variable_attributes()

func _ready():
	
	_pre_ready()
	
	# server only
	#TODO: move to avatar_spawner?
	
	avatar = avatar_prefab.instance()
	avatar.avatar_owner = self
	avatar.visible = should_sync_to_client(Lobby.local_client)
	#avatar.name = AvatarSpawner.get_unique_name()
	#get_tree().get_root()
	$"/root/Spawned/Avatars".add_child(avatar, true) #TODO: fix absolute path
	
	var initials = add_to_package({}, Attrs.VISIBLE_TO_EVERYONE | Attrs.VISIBLE_TO_TEAM_AND_SPEC, true)
	#spawn_avatar_remotely_id(1, initials)
	
	for client in Game.lists[team].values():
		if client.id != id:
			spawn_avatar_remotely_id(client.id, initials)
	
	initials = add_to_package(initials, Attrs.VISIBLE_TO_OWNER_AND_SPEC, true)
	if id:
		spawn_avatar_remotely_id(id, initials)
	
	spawned_on_team_computers[team] = true

	if team != Types.Team.Spectators:
		for client in Game.spectators.values():
			spawn_avatar_remotely_id(client.id, initials)
		spawned_on_team_computers[Types.Team.Spectators] = true

func _pre_ready():
	pass

func spawn_avatar_remotely_id(id, initials):
	if id != 1:
		AvatarSpawner.rpc_id(id, "spawn_avatar_remotely", avatar_prefab.resource_path, avatar.name, initials)
	else: # already spawned on server
		avatar.init(initials) # so just init
		avatar.visible = true

func add_to_package(pkg, access_rights, initial = false):
	for key in var_attrs:
		var attrs = var_attrs[key]
		var value = self[key]
		if attrs & access_rights && (!Attrs.CONST || initial): #&& avatar[key] != value:
			pkg[key] = value
	return pkg

func sync_opponent(opponent_team):
	if not spawned_on_team_computers[opponent_team]:
		spawned_on_team_computers[opponent_team] = true
		
		var initials = add_to_package({}, Attrs.VISIBLE_TO_EVERYONE, true)
		for player in Game.lists[opponent_team].values():
			spawn_avatar_remotely_id(player.id, initials)
	else:
		var data = add_to_package({}, Attrs.VISIBLE_TO_EVERYONE)
		for player in Game.lists[opponent_team].values():
			avatar.rpc_id(player.id, "unhide", data)

func unsync_opponent(opponent_team):
	for player in Game.lists[opponent_team].values():
		avatar.rpc_id(player.id, "hide")

func sync_set(key, value = null):
	if value == null:
		value = get(key)
	else:
		set(key, value)

#	if key != "linear_velocity":
#		print(name, ' ', key, " = ", value)

	var attrs = var_attrs.get(key) if var_attrs else null
	if attrs:
		
		var func_name = "rpc_unreliable_id" if attrs | Attrs.UNRELIABLE else "rpc_id"
		
		if attrs & Attrs.VISIBLE_TO_EVERYONE:
			for client in Game.clients.values():
				if should_sync_to_client(client):
					avatar.call(func_name, client.id, "set_remote", key, value)
		
		else:
			if attrs & Attrs.VISIBLE_TO_TEAM_AND_SPEC:
				for player in Game.lists[team].values():
					if should_sync_to_client(player):
						avatar.call(func_name, player.id, "set_remote", key, value)
			elif attrs & Attrs.VISIBLE_TO_OWNER_AND_SPEC:
				avatar.call(func_name, id, "set_remote", key, value)
			
			for spectator in Game.spectators.values():
				if should_sync_to_client(spectator):
					avatar.call(func_name, spectator.id, "set_remote", key, value)

#		return true
#	return false

#TODO: trigger this on attempt to set global_position or interpolate everything
func sync_position():
	for client in Game.clients.values():
		if should_sync_to_client(client):
			#yield(get_tree().create_timer(randf() * 0.1), "timeout")
			avatar.rpc_unreliable_id(client.id, "interpolate_position", Lobby.get_ticks_usec(), global_position)

func destroy_self():
	name = name + "_destroyed"
	#print(name, " self destroyed")
	set_process(false)
	set_physics_process(false)
	
	var ticks = Lobby.get_ticks_usec()
	for client in Game.clients.values():
		if client.id != 1 && spawned_on_team_computers[client.team]:
			avatar.rpc_id(client.id, "destroy_remote", ticks)
	
	avatar.destroy_remote(ticks)
	queue_free()
