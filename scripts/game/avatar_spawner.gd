#global AvatarSpawner
extends Node

#TODO: path to int encoding + caching

var unique_counter := -1
func get_unique_name():
	unique_counter += 1
	return "Avatar" + str(unique_counter)

var cached := {}

puppet func spawn_avatar_remotely(path: String, name: String, initial_data):
	#yield(get_tree().create_timer(0.5), "timeout")
	
	var cached_prefab = cached.get(path)
	
	print(path, " (cached)" if cached_prefab else "", " spawned as ", name)
	
	if not cached_prefab:
		cached_prefab = load(path)
		cached[path] = cached_prefab
	
	var avatar_prefab: PackedScene = cached_prefab
	var new_avatar: Avatar = avatar_prefab.instance()
	new_avatar.name = name
	#new_avatar.visible = true
	#get_tree().get_root()
	$"/root/Spawned/Avatars".add_child(new_avatar) #TODO: fix absolute path; change node or merge with spawn_manager
	new_avatar.init(initial_data)
