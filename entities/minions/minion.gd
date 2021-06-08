class_name Minion
extends Moving

func is_class(name: String):
	return name == "Minion" || .is_class(name)

var lane_line: Line2D
var vision_radius
var selected_as_target_by_num_of_minions := 0

var reward_radius: CircleShape2D
func _ready():
	set_target(null)
	vision_radius = $SightRadius/CollisionShape2D.shape.radius
	reward_radius = CircleShape2D.new()
	reward_radius.set_radius(1600)

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

func grant_gold_and_exp(to):
	#.grant_gold_and_exp(to)
	var space_state = get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	query.collision_layer = Types.champion_layer[Lobby.opposite_team[team]]
	#query.exclude = [ self ]
	query.transform = global_transform
	query.collide_with_bodies = false
	query.collide_with_areas = true

	#TODO: report bug?
	#var shape = CircleShape2D.new()
	#shape.radius = 1600
	#query.set_shape_rid(reward_radius.get_rid())
	query.set_shape(reward_radius)

	var collisions = space_state.intersect_shape(query) #, 5)
#	var found_names := []
#	for collision in collisions:
#		var entity = collision.collider.get_parent()
#		found_names.append(entity.name + "->" + collision.collider.name + " (" + String(entity.team if 'team' in entity else '?') + ")")
#	print(name, " collisions: ", found_names)

	#TODO: check distance?
	var found_champions := []
	for collision in collisions:
		var entity = collision.collider.get_parent()
		if entity != to: #&& entity.is_class("Player"):
			found_champions.append(entity)
	
	if to.is_class("Player"):
		found_champions.append(to)
	
#	var found_champion_names := []
#	for champ in found_champions:
#		found_champion_names.append(String(champ.id) + " (" + Game.players[champ.id].name + ')')
#	print(name, " found champions: ", found_champion_names)
	
	var exp_multiplier :=  1.16 if found_champions.size() > 1 else 0.93
	for champ in found_champions:
		champ.set_expirience(champ.expirience + granted_exp * exp_multiplier / found_champions.size())
	
	if to.is_class("Player"):
		to.sync_set("gold", to.gold + granted_gold)
		to.sync_set("creep_score", to.creep_score + 1)
