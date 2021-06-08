#TODO: rename to DamagableAvatar
class_name DamagableAvatar
extends Avatar

export(NodePath) onready var healthbar = get_node(healthbar)

var health := 0.0 setget set_health
func set_health(to):
	emit_stat("health", to)
	health = to

var health_max := 0.0 setget set_health_max
func set_health_max(to):
	emit_stat("health_max", to)
	health_max = to

var health_regen := 0.0 setget set_health_regen
func set_health_regen(to):
	emit_stat("health_regen", to)
	health_regen = to

var armor := 0.0 setget set_armor
func set_armor(to):
	emit_stat("armor", to)
	armor = to

var mr := 0.0 setget set_mr
func set_mr(to):
	emit_stat("mr", to)
	mr = to

var stat_connections := {}

var last_group_id := -1
func create_new_group():
	last_group_id += 1
	stat_connections[last_group_id] = {}
	return last_group_id

func connect_stat(group, stat_name, obj, func_name, binds := []):
	#print(name, " conecting stat ", stat_name, " from group ", group, " to ", obj.name, ' ', func_name)
	
	assert(stat_connections.has(group))
	assert(stat_name in self)
	
#	if !stat_name in self:
#		var args = binds.duplicate()
#		args.push_front(0)
#		obj.callv(func_name, args)
#		return
	
	var existing_signal = stat_connections[group].get(stat_name)
	if !existing_signal:
		existing_signal = []
		stat_connections[group][stat_name] = existing_signal
	
	var args = binds.duplicate()
	args.push_front(0) # will be replaced with actual value before callv
	existing_signal.append([ obj, func_name, args])
	
	args[0] = self.get(stat_name)
	obj.callv(func_name, args)
	
func disconnect_group(group):
	#print(name, " disconnecting group ", group)
	stat_connections.erase(group)

func emit_stat(stat_name, new_value):
	for group in stat_connections.values():
#		var game_ui = $"/root/Control/GUI/PageSwitcher/Page5_GameUI"
#		if group == stat_connections.get(game_ui.shared_panel.connections_group):
#			print(name, " emits stat ", stat_name, " = ", new_value, "  for shared panel")
		var existing_signal = group.get(stat_name, [])
		for connection in existing_signal:
			var obj = connection[0]
			var func_name = connection[1]
			var args = connection[2]
			args[0] = new_value
			
			#print(obj.name, " listens on ", func_name)
			obj.callv(func_name, args)

var floating_panel_connections_group
func init(initials):
	.init(initials)
	
	if should_change_color():
		healthbar.self_modulate = Color(2, 1, 1) # red
	else:
		healthbar.self_modulate = Color(1, 1.75, 2) # blue

	var fpcg = create_new_group()
	floating_panel_connections_group = fpcg
	connect_stat(fpcg, "health_max", healthbar, "set_max")
	connect_stat(fpcg, "health", healthbar, "set_value")
	
	$SelectionRadius.connect("input_event", self, "on_mouse_input")

func on_mouse_input(viewport: Object, event: InputEvent, shape_idx: int):
	Events.process_event(self, event)

func should_disable_light():
	return Lobby.local_client.team != Types.Team.Spectators && Lobby.local_client.team != team
	
func should_change_color(): # относительные командные цвета
	return should_I_change_color_if_my_team_is(team)
	
static func should_I_change_color_if_my_team_is(team):
	if Lobby.local_client.team == Types.Team.Spectators:
		return team == Types.Team.Team2
	return Lobby.local_client.team != team

#enum WaysToChangeProperty {
#	ADD,
#	UPDATE,
#	REMOVE
#}
#signal property_changed(action_type, path, value)
#puppetsync func remote_change(path: NodePath, value):
#	var obj = self
#	var count = path.get_subname_count()
#	for i in range(count - 1):
#		var subname = path.get_subname(i)
#		obj = obj.get(subname)
#
#	if typeof(obj) == TYPE_DICTIONARY:
#		var subname = path.get_subname(count - 1)
#		if obj.has(subname):
#			if value == null:
#				obj.erase(subname)
#				emit_signal("property_changed", WaysToChangeProperty.REMOVE, path, value)
#			else:
#				obj.set(subname, value)
#				emit_signal("property_changed", WaysToChangeProperty.UPDATE, path, value)
#		elif value != null:
#			obj.set(subname, value)
#			emit_signal("property_changed", WaysToChangeProperty.ADD, path, value)

var effects := {}

signal effect_applied(data)
puppetsync func apply_effect(name, at_time, duration, stacks):
	print(self.name, " apply_effect ", name, " ", duration, " ", stacks)
	var data = {
		"name": name,
		"time_of_applying": at_time,
		"duration": duration,
		"stacks": stacks
	}
	effects[name] = data
	emit_signal("effect_applied", data)

signal effect_duration_set(to)
puppetsync func set_effect_duration(name, duration):
	print(self.name, " set_effect_duration ", name, " ", duration)
	effects[name].duration = duration
	emit_signal("effect_duration_set", duration)

signal effect_stacks_set(to)
puppetsync func set_effect_stacks(name, stacks):
	print(self.name, " set_effect_stacks ", name, " ", stacks)
	effects[name].stacks = stacks
	emit_signal("effect_stacks_set", stacks)

signal effect_dispelled(name)
puppetsync func dispel_effect(name):
	print(self.name, " dispel_effect ", name)
	effects.erase(name)
	emit_signal("effect_dispelled", name)

func remove_outdated_effects():
	for name in effects:
		var effect = effects[name]
		var server_time = Lobby.get_ticks_usec() + Lobby.server_time_offset
		if effect.time_of_applying + effect.duration * Lobby.sec_to_server_time_mul < server_time:
			effects.erase(name)

