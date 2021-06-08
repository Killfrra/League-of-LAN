#TODO: rename to SightArea
class_name VisionArea, "res://editor_icons/true_sight_icon.svg"
extends Area2D

onready var parent = get_parent()

func _ready():
	
	#if Lobby.local_client.id == 1:
	var team = get_parent().team
	var opposite_layer = Types.team2vision_layers[Lobby.opposite_team[team]]
	collision_layer = opposite_layer
	collision_mask = opposite_layer
	connect("area_entered", self, "on_area_entered")
	connect("area_exited", self, "on_area_exited")
	if parent.has_signal("moved"):
		parent.connect("moved", self, "_on_parent_moved")

var tracked_seen := {}

func on_area_entered(area: Area2D):
	var entity = area.get_parent()
	if entity != get_parent():
		#print(name, " on_area_entered ", entity.name)
		tracked_seen[entity] = false
		if entity.has_signal("moved"):
			#print(name, " connected moved signal to ", entity.name)
			entity.connect("moved", self, "_check_visibility", [entity])
		_check_visibility(entity)
	
func on_area_exited(area: Area2D):
	var entity = area.get_parent()
	if entity != get_parent():
		if entity.has_signal("moved"):
			#print(name, " disconnect moved signal to ", entity.name)
			entity.disconnect("moved", self, "_check_visibility")
		if tracked_seen[entity]:
			if !entity.is_queued_for_deletion():
				entity.on_unseen_by(get_parent())
			tracked_seen.erase(entity)

func _on_parent_moved():
	for obj in tracked_seen:
		if is_instance_valid(obj):
			_check_visibility(obj)
		else:
			tracked_seen.erase(obj)

func _check_visibility(target):
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, target.global_position, [self], Types.team2vision_blocking_layer[get_parent().team], true, true)
	if result:
		if tracked_seen[target]:
			tracked_seen[target] = false
			target.on_unseen_by(get_parent())
		return false
	else:
		if !tracked_seen[target]:
			tracked_seen[target] = true
			target.on_seen_by(get_parent())
		return true
