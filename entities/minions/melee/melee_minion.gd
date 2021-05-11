class_name MeleeMinon
extends Minion

func is_class(name: String):
	return name == "MeleeMinon" || .is_class(name)

var sleeping := true
var radio_silence := true
#TODO: Temporary Caster Minion Ignore
#TODO: Ignore Allied Collision before lane ("ghosted for 25s"?)

func _ready():
	$WakeUpRadius.connect("area_entered", self, "wake_up")
	var opposite_team_layer = Types.team2gameplay_layers[Lobby.opposite_team[team]]
	$WakeUpRadius.collision_mask = opposite_team_layer
	$FirstAcquisitionRadius.collision_mask = opposite_team_layer
	

func on_autoacquisition_area_entered(area):
	if not sleeping:
		.on_autoacquisition_area_entered(area)

func on_autoacquisition_area_exited(area: Area2D):
	if not sleeping:
		.on_autoacquisition_area_exited(area)

#func damaged_by(damager):
#	wake_up()

func on_enemy_hit_smth(what, who):
	
	#if radio_silence and who is Player:
	#	radio_silence = false
	
	if not radio_silence:
		.on_enemy_hit_smth(what, who)

func on_target_killed_by(killer):
	.on_target_killed_by(killer)
	radio_silence = false

func set_target(to):
	if typeof(target) == TYPE_OBJECT:
		if target is Player:
			radio_silence = false
		if "selected_as_target_by_num_of_minions" in target:
			target.selected_as_target_by_num_of_minions -= 1
	.set_target(to)
	if typeof(target) == TYPE_OBJECT && "selected_as_target_by_num_of_minions" in target:
		target.selected_as_target_by_num_of_minions += 1
		#print(name, " selects ", target.name, " as target")

func wake_up(_area = null):
	
	if not sleeping:
		return
	
	sleeping = false
	#print(name, " woked up by ", _area.get_parent().name)
	
	try_to_find_target_in_area($FirstAcquisitionRadius)
	
	if typeof(target) == TYPE_OBJECT:
		target_locked = true
		#print(name, " ", target, target.get_child_count(), target.get_child(0))
		on_autoacquisition_area_entered(target.get_child(0))
		target_locked = false
	
	$WakeUpRadius.queue_free()
	$FirstAcquisitionRadius.queue_free()

	for area in $AcquisitionRadius.get_overlapping_areas():
		if not strict_equality(target, area.get_parent()):
			on_autoacquisition_area_entered(area)
			
func calc_priority(candidate, vicium = null):
	var score = .calc_priority(candidate, vicium)
	if not "selected_as_target_by_num_of_minions" in candidate || candidate.selected_as_target_by_num_of_minions > 0:
		score -= 1
	return score
