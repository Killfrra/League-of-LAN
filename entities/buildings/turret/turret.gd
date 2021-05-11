class_name Turret
extends Autoattacking

var vision_radius

export(NodePath) onready var protects = get_node(protects) if protects else null # as Damagable

func _ready():
	seen_by_teams = [ 0, 1, 1 ]
	seen_by_num = 2
	sync_opponent(Lobby.opposite_team[team])
	avatar.visible = true
	
	vision_radius = $SightRadius/CollisionShape2D.shape.radius
	
	if protects:
		protects.invulnerable = true
		protects.untargetable = true
	
func killed_by(killer):
	if protects:
		protects.invulnerable = false
		protects.untargetable = false
	.killed_by(killer)

func set_target(to):
	.set_target(to)
	if target != null:
		avatar.head_to(target.avatar.get_path(), reload_timer.time_left)

func on_seen_by(entity):
	pass
	
func on_unseen_by(entity):
	pass

func calc_priority(candidate: Node2D, victim = null):
	var score = 0
	if candidate is Player and victim is Player:
		score += 3
	elif candidate.is_class("MeleeMinon"):
		score += 2
	elif candidate.is_class("Minion"):
		score += 1
	score += 1 - min(1, candidate.global_position.distance_to(global_position) / vision_radius)
	#print(name, " ", candidate.name, " ", score)
	return score
