class_name LobbyUI_Page2_ConnectOrHostGame
extends Control

export(NodePath) onready var hostIP_field = get_node(hostIP_field)		 #as LineEdit
export(NodePath) onready var game_name_field = get_node(game_name_field) #as LineEdit
export(NodePath) onready var team_size_field = get_node(team_size_field) #as SpinBox

func _ready():
	Lobby.connect("logged_in", self, "_on_Game_logged_in")
	
func _on_Game_logged_in(username):
	hostIP_field   .text = Lobby.get_ip() #"127.0.0.1"
	game_name_field.text = username + "'s game"
	get_parent().enable_step(1)

func _on_Connect_pressed():
	var serverIP: String = hostIP_field.text
	Lobby.connect_to(serverIP)

func _on_Create_pressed():
	var gamename: String = game_name_field.text
	var teamsize: int = team_size_field.value
	var gamemap = Types.Map.HowlingAbyss
	var gametype = Types.Type.BlindPick
	Lobby.host(gamename, teamsize, gamemap, gametype)
