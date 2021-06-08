class_name Effect
extends Reference

#var name setget, get_name
func get_name():
	return "undefined"

#func is_debuff():
#	return false

var _duration: float = INF setget set_duration
func set_duration(to):
	_duration = to
	#TODO: move to func?
	for client in Game.clients.values():
		if applied_to.should_sync_to_client(client):
			applied_to.avatar.rpc_id(client.id, "set_effect_duration", get_name(), to)

var _stacks := -1 setget set_stacks
func set_stacks(to):
	_stacks = to
	#TODO: move to func?
	for client in Game.clients.values():
		if applied_to.should_sync_to_client(client):
			applied_to.avatar.rpc_id(client.id, "set_effect_stacks", get_name(), to)

func apply(to):
	if "effects" in to:
		var name = get_name()
		var already_existed = to.effects.get(name)
		if already_existed:
			already_existed._stack(self)
		else:
			to.effects[name] = self
			_apply(to)
			#TODO: move to func?
			for client in Game.clients.values():
				if applied_to.should_sync_to_client(client):
					applied_to.avatar.rpc_id(client.id, "apply_effect", get_name(), Lobby.get_ticks_usec(), _duration, _stacks)

var applied_to
func _apply(to):
	print(get_name(), " effect applied to ", to.name)
	applied_to = to
	
func _stack(with):
	print(get_name(), " effect stacked on ", applied_to.name)
	
func _dispel():
	print(get_name(), " effect dispelled on ", applied_to.name)
	applied_to.effects.erase(get_name())
	#TODO: move to func?
	for client in Game.clients.values():
		if applied_to.should_sync_to_client(client):
			applied_to.avatar.rpc_id(client.id, "dispel_effect", get_name())
