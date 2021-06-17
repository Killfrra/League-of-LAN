class_name AcquisitionArea, "res://editor_icons/acquisition_range.svg"
extends Area2D

signal entity_entered(intruder)
signal entity_exited(escapee)

export var tracking := true

onready var parent = get_parent()
var team = null
#onready var team = parent.team if "team" in parent else null

var tracked_entities := {}

func _ready():
	#if team:
	#	setup_layers()
	if tracking:
		connect("area_entered", self, "on_area_entered")
		connect("area_exited", self, "on_area_exited")
		
func set_team(to):
	team = to
	setup_layers()

func setup_layers():
	var opposite_layer = Types.team2gameplay_layers[Lobby.opposite_team[team]]
	collision_layer = opposite_layer
	collision_mask = opposite_layer

#func connect(signal_name, obj, func_name, binds=[], mode=0):
#	pass

#TODO: rename
func get_overlapping_areas():
	if tracking:
		return tracked_entities
	var res := []
	for area in .get_overlapping_areas():
		var entity = area.get_parent()
		if entity != parent && entity.seen_by_teams[team]:
			res.append(entity)
	return res

func _entity_entered(entity):
	#print(parent.name, ' ', name, " _entity_entered(", entity.name, ")")
	tracked_entities[entity] = true
	emit_signal("entity_entered", entity)
	
func _entity_exited(entity):
	tracked_entities.erase(entity)
	emit_signal("entity_exited", entity)

func on_area_entered(area: Area2D):
	var entity = area.get_parent()
	if entity != parent:
		entity.connect("in_sight", self, "on_tracked_in_sight", [entity])
		entity.connect("out_of_sight", self, "on_tracked_out_of_sight", [entity])
		entity.connect("killed_by", self, "on_tracked_killed", [entity])
		if entity.seen_by_teams[team]:
			_entity_entered(entity)

func on_area_exited(area: Area2D):
	var entity = area.get_parent()
	if entity != parent:
		entity.disconnect("in_sight", self, "on_tracked_in_sight")
		entity.disconnect("out_of_sight", self, "on_tracked_out_of_sight")
		entity.disconnect("killed_by", self, "on_tracked_killed")
		if entity.seen_by_teams[team]:
			_entity_exited(entity)

func on_tracked_in_sight(for_team, entity):
	if for_team == team:
		_entity_entered(entity)
	
func on_tracked_out_of_sight(for_team, entity):
	if for_team == team:
		_entity_exited(entity)

func on_tracked_killed(by, entity):
	_entity_exited(entity)
