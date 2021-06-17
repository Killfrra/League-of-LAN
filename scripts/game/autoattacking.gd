class_name Autoattacking
extends Damagable

#TODO: what if untargetable becomes targetable again?

export(float) var attack_damage: float
export(float) var attack_speed: float
export(PackedScene) onready var bullet_prefab: PackedScene
export(float) var attack_range := 550.0

signal hit_on_target(target)

var target = null
var target_locked := false
var target_score: float
var target_in_range := false
var reload_timer: Timer
var ready_to_fire := true

var acquisition_area: AcquisitionArea

func generate_variable_attributes():
	.generate_variable_attributes()
	var_attrs["attack_damage"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["attack_speed"] = Attrs.VISIBLE_TO_EVERYONE

func _ready():

	assert(Lobby.local_client.id == 1)
	
	acquisition_area = get_node_or_null("AcquisitionRadius")
	if acquisition_area:
		acquisition_area.set_team(team)
		acquisition_area.connect("entity_entered", self, "on_autoacquisition_area_entered")
		acquisition_area.connect("entity_exited", self, "on_autoacquisition_area_exited")

	reload_timer = Timer.new()
	reload_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	reload_timer.wait_time = 1 / attack_speed
	reload_timer.connect("timeout", self, "on_ready_to_fire")
	add_child(reload_timer)

func check_if_target_in_attack_range():
	target_in_range = global_position.distance_to(target.global_position) - gameplay_radius - target.gameplay_radius < attack_range * SIZE_MULTIPLIER
	return target_in_range

func strict_equality(a, b):
	return typeof(a) == typeof(b) && a == b

func connect_signals_to_target():
	if target.has_signal("moved"):
		target.connect("moved", self, "on_target_moved", [target])
	target.connect("killed_by", self, "on_target_killed_by")
	target.connect("out_of_sight", self, "on_target_is_out_of_sight")
	
func disconnect_signals_from_target():
	if typeof(target) == TYPE_OBJECT:
		if target.has_signal("moved"):
#			if not target.is_connected("moved", self, "on_target_moved"):
#				print("bug: trying to disconnect not connected signal ", name, ' ', target.name)
			target.disconnect("moved", self, "on_target_moved")
		target.disconnect("killed_by", self, "on_target_killed_by")
		target.disconnect("out_of_sight", self, "on_target_is_out_of_sight")

func set_target(to): # to Vector2 or Object or null

	if not strict_equality(to, target):
		disconnect_signals_from_target()
		
		target = to
		
		if typeof(target) == TYPE_OBJECT:
			connect_signals_to_target()
			check_if_target_in_attack_range()
			fire_if_possible()
		else:
			target_in_range = false

func on_autoacquisition_area_entered(entity):
	if entity.has_signal("hit_on_target") && not entity.is_connected("hit_on_target", self, "on_enemy_hit_smth"):
		entity.connect("hit_on_target", self, "on_enemy_hit_smth", [entity])
	if !target_locked && _targetable(entity):
		if typeof(target) == TYPE_OBJECT:
			on_enemy_hit_smth(null, entity)
		else: #if parent is Damagable:
			set_target(entity)

func on_autoacquisition_area_exited(entity):
	if entity.has_signal("hit_on_target") && entity.is_connected("hit_on_target", self, "on_enemy_hit_smth"):
		entity.disconnect("hit_on_target", self, "on_enemy_hit_smth")

#TODO: introduce tracked_candidates in autoattacking

func on_enemy_hit_smth(what, who):
	if health <= 0:
		print("hello from another side (on_enemy_hit_smth)")
	
	# We saw nothing
#	if !who.seen_by_teams[team]:
#	#TODO: disconnect on_enemy_hit_smth when target is out of sight?
#		return

	if strict_equality(who, target):
		target_score = calc_priority(target, what)
	elif !target_locked && _targetable(who):
		var new_score = calc_priority(who, what)
		if new_score > target_score:
			set_target(who)
			target_score = new_score

func on_target_moved(which): #TODO: failsafe
	
	assert(target == which)
	
	if health <= 0:
		print("hello from another side (on_target_moved)")
	
	check_if_target_in_attack_range()
	fire_if_possible()

func on_target_killed_by(killer):
	if health <= 0:
		print("hello from another side (on_target_killed_by)")
	
	target_locked = false
	try_to_find_target_in_area(acquisition_area)

func on_target_is_out_of_sight(team_from):
	#disconnect_signals_from_target()
	if team_from == team && !target_locked:
		try_to_find_target_in_area(acquisition_area)

func _targetable(candidate): # autotargetable
	#&& candidate.seen_by_teams[team]
	return !candidate.untargetable && (candidate.team != Types.Team.Spectators || strict_equality(candidate.target, self)) # do not attack monsters and bullets!

func try_to_find_target_in_area(search_area: AcquisitionArea): #try_to_find_another_target_in_area
	var max_score
	var candidate_with_max_score = null
	for candidate in search_area.get_overlapping_areas():
		if not strict_equality(candidate, target) && is_instance_valid(candidate) && _targetable(candidate):
			var candidate_score = calc_priority(candidate)
			if candidate_with_max_score == null || candidate_score > max_score:
				max_score = candidate_score
				candidate_with_max_score = candidate

	set_target(
		candidate_with_max_score
	)
	
	#if candidate_with_max_score && strict_equality(target, candidate_with_max_score)
	if typeof(target) == TYPE_OBJECT && target == candidate_with_max_score:
		target_score = max_score

func calc_priority(candidate: Node2D, victim = null):
	return 0

func killed_by(killer):
	
	reload_timer.stop()
	
	disconnect_signals_from_target()
	acquisition_area.disconnect("entity_entered", self, "on_autoacquisition_area_entered")
	acquisition_area.disconnect("entity_exited", self, "on_autoacquisition_area_exited")
	
	for entity in acquisition_area.get_overlapping_areas():
		on_autoacquisition_area_exited(entity)
	
	.killed_by(killer)

var attacking_disallowed := 0

func on_ready_to_fire():
	if target_in_range and !attacking_disallowed:
		fire()
	else:
		ready_to_fire = true
		reload_timer.stop()

func fire():
	
	if bullet_prefab != null:
		var bullet = bullet_prefab.instance()
		bullet.team = Types.Team.Spectators
		bullet.sender = self
		bullet.global_position = global_position
		bullet.target = target
		bullet.physic_damage = attack_damage
		
		$"/root/Spawned".call_deferred("add_child", bullet, true)
	else:
		target.take_damage(self, 0, 0, attack_damage)
	
	ready_to_fire = false
	
func fire_if_possible():
	if target_in_range and ready_to_fire and !attacking_disallowed:
		fire()
		reload_timer.start()
