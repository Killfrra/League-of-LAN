extends Node2D

#TODO: area.collision.disabled vs area.queue_free()
#export(Array, NodePath) #TODO: very strange bug
var flame_spawn_points := [ NodePath("Flame1"), NodePath("Flame2"), NodePath("Flame3") ]
export var flame_prefab: PackedScene
var flames := []

var sender: Player
var damage: float
var additional_damage: float

var tween := Tween.new()

func _ready():
	
	#print(name, "_ready")
	scale = Vector2.ZERO
	
	for i in range(3): #flame_spawn_points.size()):
		#if typeof(flame_spawn_points[i]) == TYPE_OBJECT:
		#	print(i, ' ', flame_spawn_points[i].name, ' ', flame_spawn_points[i].get_parent().name)
		#	get_tree().paused = true
		#	return
		flame_spawn_points[i] = get_node(flame_spawn_points[i])

	for flame_sp in flame_spawn_points:
		
		var acquisition_radius = flame_sp.get_node("AcquisitionRadius")
		acquisition_radius.set_team(sender.team)
		
		var flame = flame_prefab.instance()
		flame.sender = sender
		flame.global_position = global_position
		$"/root/Spawned".add_child(flame, true)
		flame.set_physics_process(false) # should be after addition
		#print("_physics_process disabled")
		flames.append(flame)
	
	tween.playback_process_mode = Tween.TWEEN_PROCESS_PHYSICS
	tween.interpolate_property(self, "scale", Vector2.ZERO, Vector2.ONE, 0.25)
	tween.connect("tween_completed", self, "on_tween_completed")
	add_child(tween)
	tween.start()
	
	var self_destroy_timer := Timer.new()
	self_destroy_timer.one_shot = true
	self_destroy_timer.wait_time = 5.0
	self_destroy_timer.connect("timeout", self, "on_destroy_timer_timeout")
	add_child(self_destroy_timer)
	self_destroy_timer.start()

var should_destroy := false
func on_destroy_timer_timeout():
	should_destroy = true
	for flame_sp in flame_spawn_points:
		#if is_instance_valid(flame_sp):
		flame_sp.get_node("AcquisitionRadius/CollisionShape2D").set_deferred("disabled", true)
	tween.remove_all()
	tween.interpolate_property(self, "scale", Vector2.ONE, Vector2.ZERO, 0.25)
	tween.start()

func _physics_process(delta):
	rotation = lerp_angle(rotation, rotation + 2.65, delta)
	for i in range(3): #flame_spawn_points.size()):
		var flame = flames[i]
		var flame_sp = flame_spawn_points[i]
		if is_instance_valid(flame) && (!flame.is_physics_processing() || flame.first_frame):
			flame.global_position = flame_sp.global_position
			flame.sync_position()

var targets = []

func release_flame(flame_sp, flame, target):
	
	#print("releaseing flame to ", target.name)
	
	flame.target = target
	
	#TODO: on_target_reached
	if targets.find(target) != -1:
		flame.magic_damage = damage
		targets.append(target)
	else:
		flame.magic_damage = additional_damage
	
	flame.set_physics_process(true)
	
	flame_sp.get_node("AcquisitionRadius/CollisionShape2D").set_deferred("disabled", true) #queue_free()
	if targets.size() == 3:
		queue_free()

func on_tween_completed(object: Object, key: NodePath):
	
	#print("on_tween_completed")
	if should_destroy:
		for flame in flames:
			if is_instance_valid(flame) && !flame.is_physics_processing():
				flame.destroy_self()
		queue_free()
		return
	
	var target = try_to_find_priority_target()
	if target:
		#print("found priority target")
		for i in range(3):
			release_flame(flame_spawn_points[i], flames[i], target)
	else:
		#TODO: убрать, потому что теоритически может сработать после удаления объекта?
		yield(get_tree().create_timer(0.4), "timeout")
		for i in range(3): #flame_spawn_points.size()):
			var flame = flames[i]
			var flame_sp = flame_spawn_points[i]
			var acquisition_radius = flame_sp.get_node("AcquisitionRadius")
			target = try_to_find_nearest_target(acquisition_radius)
			if target:
				#print("found target")
				release_flame(flame_sp, flame, target)
			else:
				acquisition_radius.connect("entity_entered", self, "on_flame_acquisition_area_entered", [acquisition_radius, flame, flame_sp])

func safely_targetable(candidate):
	return is_instance_valid(candidate) && !candidate.untargetable #&& candidate.team != Types.Team.Spectators

func on_flame_acquisition_area_entered(target, acquisition_area, flame, flame_sp):
	#if !flame_sp.is_queued_for_deletion() &&
	if safely_targetable(target):
		#print("target entered")
		release_flame(flame_sp, flame, target)
		acquisition_area.disconnect("entity_entered", self, "on_flame_acquisition_area_entered")

func try_to_find_priority_target():
	var search_area: VisionSubArea = sender.get_node("FoxFireRadius")
	var max_score
	var candidate_with_max_score = null
	for candidate in search_area.get_overlapping_areas():
		
		if safely_targetable(candidate):
			
			var candidate_score = 0
			if candidate.has_method("is_class"):
				if candidate.is_class("Player"):
					candidate_score = 3
				elif candidate.is_class("Minion") && candidate.health < damage + additional_damage * 2:
					candidate_score = 2
			if candidate_score < 1 && candidate == sender.target_of_last_autoattack && Lobby.get_ticks_msec() - sender.was_attacked_in_time < 3000:
				candidate_score = 1
				
			if candidate_score != 0 && (candidate_with_max_score == null || candidate_score > max_score):
				max_score = candidate_score
				candidate_with_max_score = candidate
	
			#print(candidate.name, " score is ", candidate_score)
	
	#if candidate_with_max_score:
	#	print(candidate_with_max_score.name, " score is ", max_score)
	return candidate_with_max_score

func try_to_find_nearest_target(search_area):
	var min_dist := -1.0
	var candidate_with_min_dist = null
	for candidate in search_area.get_overlapping_areas():
		if safely_targetable(candidate):
			var dist = search_area.global_position.distance_to(candidate.global_position)
			if min_dist == -1 || dist < min_dist:
				min_dist = dist
				candidate_with_min_dist = candidate
	return candidate_with_min_dist
