#global AvatarSpawner
extends Node

#TODO: path to int encoding + caching

var unique_counter := -1
func get_unique_name():
	unique_counter += 1
	return "Avatar" + str(unique_counter)

puppet func spawn_avatar_remotely(path: String, name: String, initial_data):
	print(path, " spawned as ", name)
	#yield(get_tree().create_timer(0.5), "timeout")
	var avatar_prefab: PackedScene = load(path)
	var new_avatar: Avatar = avatar_prefab.instance()
	new_avatar.name = name
	#new_avatar.visible = true
	#get_tree().get_root()
	$"/root/Control/Avatars".add_child(new_avatar) #TODO: fix absolute path; change node or merge with spawn_manager
	new_avatar.init(initial_data)
