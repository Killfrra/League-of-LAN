class_name VisionArea
extends Area2D

func _ready():
	
	#if Lobby.local_client.id == 1:
	var team = get_parent().team
	var opposite_layer = Types.team2vision_layers[Lobby.opposite_team[team]]
	collision_layer = opposite_layer
	collision_mask = opposite_layer
	connect("area_entered", self, "on_area_entered")
	connect("area_exited", self, "on_area_exited")

func on_area_entered(area: Area2D):
	var entity = area.get_parent()
	if entity != get_parent():
		entity.on_seen_by(get_parent())
	
func on_area_exited(area: Area2D):
	var entity = area.get_parent()
	if entity != get_parent():
		if !entity.is_queued_for_deletion():
			entity.on_unseen_by(get_parent())
		#else:
		#	print("vision_area.gd:24 saved (approved)")
