class_name Minion
extends Moving

var lane_line: Line2D
var vision_radius
var selected_as_target_by_num_of_minions := 0

func is_class(name: String):
	return name == "Minion"

func _ready():
	set_target(null)
	vision_radius = $SightRadius/CollisionShape2D.shape.radius

func set_target(to):
	if to == null:
		.set_target(lane_line.points[lane_line.points.size() - 1])
	else:
		.set_target(to)

func calc_priority(candidate: Node2D, victim = null):
	var score = 0
	if candidate is Player and victim is Player:
		score += 7
	elif candidate as Minion and victim is Player:
		score += 6
	elif candidate as Minion and victim as Minion:
		score += 5
	elif candidate is Turret and victim as Minion:
		score += 4
	elif candidate is Player and victim as Minion:
		score += 3
	elif candidate as Minion:
		score += 2
	elif candidate is Player:
		score += 1
	score += 1 - min(1, candidate.global_position.distance_to(global_position) / vision_radius)
	#print(name, " ", candidate.name, " ", score)
	return score
