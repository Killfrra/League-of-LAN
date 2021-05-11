class_name Autoattacking
extends Damagable

var acquisition_radius
export(float) var damage: float
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

var acquisition_area

func _ready():
	
	assert(Lobby.local_client.id == 1)
	
	acquisition_area = get_node_or_null("AcquisitionRadius")
	if acquisition_area:
		var opposite_layer = Types.team2gameplay_layers[Lobby.opposite_team[team]]
		acquisition_area.collision_layer = opposite_layer
		acquisition_area.collision_mask = opposite_layer
		acquisition_radius = acquisition_area.get_node("CollisionShape2D").shape.radius * SIZE_MULTIPLIER
		acquisition_area.connect("area_entered", self, "on_autoacquisition_area_entered")
		acquisition_area.connect("area_exited", self, "on_autoacquisition_area_exited")
	
	reload_timer = Timer.new()
	reload_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	reload_timer.wait_time = 1 / attack_speed
	reload_timer.connect("timeout", self, "on_ready_to_fire")
	add_child(reload_timer)

func check_if_target_in_attack_range():
	#target != null && is_instance_valid(target) &&
	target_in_range = global_position.distance_to(target.global_position) - gameplay_radius - target.gameplay_radius < attack_range * SIZE_MULTIPLIER
	#print(global_position.distance_to(target.global_position), " - ", gameplay_radius, " - ", target.gameplay_radius, " < ", attack_range, " * ", SIZE_MULTIPLIER)
	return target_in_range

#func is_valid_object_to_target(to):
#	return typeof(to) == TYPE_OBJECT && is_instance_valid(to) && !to.is_queued_for_deletion() && to.health > 0 && !to.untargetable

#func is_valid_to_target(to):
#	return to == null || typeof(to) == TYPE_VECTOR2 || is_valid_object_to_target(to)

func strict_equality(a, b):
	return typeof(a) == typeof(b) && a == b

func set_target(to): # to Vector2 or Object or null
	"""
	if to == null || typeof(to) == TYPE_VECTOR2:
		print(name, " set_target ", to)
	elif is_instance_valid(to):
		print(name, " set_target ", to.name)
	else:
		print(name, " set_target ", to, " (invalid)")
	"""
	if not strict_equality(to, target):
		
		if typeof(target) == TYPE_OBJECT:
			#print("autoattacking.gd:45 ", target)
			if target.has_signal("moved"):
				target.disconnect("moved", self, "on_target_moved")
			target.disconnect("killed_by", self, "on_target_killed_by")
			#print(name, " disconnected killed_by signal to ", target.name)
		
		target = to
		
		if typeof(target) == TYPE_OBJECT:
			if target.has_signal("moved"):
				target.connect("moved", self, "on_target_moved", [target])
			target.connect("killed_by", self, "on_target_killed_by")
			#print(name, " connected killed_by signal to ", target.name)
			check_if_target_in_attack_range()
			#print(name, " target_in_range=", target_in_range, " ", global_position.distance_to(target.global_position), " < ", attack_range * SIZE_MULTIPLIER)
			fire_if_possible()
		else:
			target_in_range = false

func on_autoacquisition_area_entered(area):
	#print(name, " on_autoacquisition_area_entered by ", area.get_parent().name)
	#if is_instance_valid(area) && !area.is_queued_for_deletion():
	
	var area_parent = area.get_parent()
	if area_parent.has_signal("hit_on_target") && not area_parent.is_connected("hit_on_target", self, "on_enemy_hit_smth"):
		#TODO: fix "already connected" error
		area_parent.connect("hit_on_target", self, "on_enemy_hit_smth", [area_parent])
	if !target_locked && !area_parent.untargetable:
		if typeof(target) == TYPE_OBJECT:
			on_enemy_hit_smth(null, area_parent)
		else: #if parent is Damagable:
			set_target(area_parent)
				
	#else:
	#	print("autoattacking.gd:95 saved")

func on_autoacquisition_area_exited(area: Area2D):
	#if is_instance_valid(area) && !area.is_queued_for_deletion():
		
	var area_parent = area.get_parent()
	if area_parent.has_signal("hit_on_target") && area_parent.is_connected("hit_on_target", self, "on_enemy_hit_smth"):
		area_parent.disconnect("hit_on_target", self, "on_enemy_hit_smth")
			
	#else:
	#	print("autoattacking.gd:105 saved")
		
func on_enemy_hit_smth(what, who):
	
	#print(name, " hit_on_target ", who.name, what.name if what else what)
	
	if health <= 0:
		print("hello from another side")
	
	#if is_instance_valid(who) && !who.is_queued_for_deletion():
		
		#if is_instance_valid(what) && !what.is_queued_for_deletion():
		
	#print("minion.gd:3 ", target)
	if strict_equality(who, target):
		target_score = calc_priority(target, what)
	elif !target_locked && !who.untargetable:
		var new_score = calc_priority(who, what)
		if new_score > target_score:
			#print(who.name, " ", new_score, " > ", target_score, " ", target.name if typeof(target) == TYPE_OBJECT else target)
			set_target(who)
			target_score = new_score
				
		#else:
		#	print("autoattacking.gd:138 saved")
		
	#else:
	#	print("autoattacking.gd:126 saved")

func on_target_moved(which): #TODO: failsafe
	
	#print(name, " moved ", which.name if which else which)
	
	#if typeof(target) == TYPE_VECTOR2:
	#	print("on_target_moved called by", which)
	
	if health <= 0:
		print("hello from another side")
	
	check_if_target_in_attack_range()
	fire_if_possible()

func on_target_killed_by(killer):
	
	#print(name, " killed_by ", killer.name if killer else killer)
	
	if health <= 0:
		print("hello from another side")
	
	target_locked = false
	#print("autoattacking.gd:105 ", target_locked)
	try_to_find_target_in_area(acquisition_area)

func try_to_find_target_in_area(search_area): #try_to_find_another_target_in_area
	var max_score
	var candidate_with_max_score = null
	for area in search_area.get_overlapping_areas():
		var candidate = area.get_parent()
		#if not is_valid_object_to_target(candidate): #TODO: why should I check? upd. not always helps
		if strict_equality(candidate, target):
			continue
		if !is_instance_valid(candidate):
			#print("autoattacking.gd:170 saved (approved)")
			continue
		if candidate.untargetable:
			#print("autoattacking.gd:170 saved (", candidate.name, ")")
			continue
		if candidate.team == Types.Team.Spectators: # do not attack monsters and bullets!
			continue
		var candidate_score = calc_priority(candidate)
		if candidate_with_max_score == null || candidate_score > max_score:
			max_score = candidate_score
			candidate_with_max_score = candidate

	#if candidate_with_max_score != null:
	#	print("best candidate for ", name, " is ", candidate_with_max_score.name, " from Team", candidate_with_max_score.team)

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
	"""
	if typeof(target) == TYPE_OBJECT:
		#print("autoattacking.gd:45 ", target)
		if target.has_signal("moved"):
			target._disconnect_("moved", self, "on_target_moved")
		target._disconnect_("killed_by", self, "on_target_killed_by")
	
	for area in $AcquisitionRadius.get_overlapping_areas():
		on_autoacquisition_area_exited(area)
	"""
	.killed_by(killer)

func on_ready_to_fire():
	if target_in_range:
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
		bullet.physic_damage = damage
		
		#get_tree().get_root().add_child(bullet, true) #TODO: fix runtime errors
		get_tree().get_root().call_deferred("add_child", bullet, true)
	else:
		#print("autoattacking.gd:100 ", target)
		#if !is_instance_valid(target):
		#	print(name)
		target.take_damage(self, 0, 0, damage)
	
	ready_to_fire = false
	
func fire_if_possible():
	if target_in_range and ready_to_fire:
		#print("autoattacking.gd:107 ", target)
		fire()
		reload_timer.start()
