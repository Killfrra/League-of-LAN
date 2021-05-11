class_name Player
extends Moving

var id
export(PackedScene) var totem_prefab: PackedScene

var vision_radius: float

func _ready():
	#TODO: move to autoattacking?
	vision_radius = $SightRadius/CollisionShape2D.shape.radius

func lock_target(to):
	target_locked = true
	#print("player.gd:9 ", target_locked)
	if typeof(to) != TYPE_OBJECT || !to.untargetable && !to.team == team:
		.set_target(to)

func spawn_totem(pos):
	var totem = totem_prefab.instance()
	totem.team = team
	totem.global_position = pos
	get_tree().get_root().add_child(totem, true)

func killed_by(killer):
	pass #TODO: respawn

func calc_priority(candidate, victium=null):
	var score = 0
	score += 1 - min(1, candidate.global_position.distance_to(global_position) / vision_radius)
	return score
