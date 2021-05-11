class_name GameUI
extends Control

func _ready():
	Lobby.connect("spawn", self, "on_Game_spawn")

func on_Game_spawn(team_choices):
	get_parent().enable_step(4)
