class_name Hiding
extends Node2D

export(Types.Team) var team
var seen_by_teams := [0, 0, 0]
onready var seen_by_num = seen_by_teams[0] + seen_by_teams[1] + seen_by_teams[2]

func on_seen_by(entity):
	assert(entity.team != Types.Team.Spectators)
	seen_by_teams[entity.team] += 1
	seen_by_num += 1
	if seen_by_teams[entity.team] == 1:
		sync_opponent(entity.team)
	#print(name, " seen by ", entity.name, " so nums are ", seen_by_teams)
	
func sync_opponent(opponent_team):
	pass
	
func on_unseen_by(entity):
	assert(entity.team != Types.Team.Spectators)
	seen_by_teams[entity.team] -= 1
	seen_by_num -= 1
	if seen_by_teams[entity.team] == 0:
		unsync_opponent(entity.team)
	#print(name, " unseen by ", entity.name, " so nums are ", seen_by_teams)

func unsync_opponent(opponent_team):
	pass

func should_sync_to_client(client, only_for_teammates := false):
	return client.team == team || client.team == Types.Team.Spectators || (seen_by_teams[client.team] > 0 && !only_for_teammates)
