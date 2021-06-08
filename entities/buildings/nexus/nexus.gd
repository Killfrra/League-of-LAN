class_name Nexus
extends Damagable

func killed_by(killer):
	Lobby.end_game(killer.team)
