class_name LobbyUI_Page3_JoinTeam
extends Control

export(NodePath) onready var game_name_label = get_node(game_name_label) #as Label
export(NodePath) onready var map_size_type_label = get_node(map_size_type_label) #as Label
export(NodePath) onready var team1_list = get_node(team1_list) #as VBoxContainer?
export(NodePath) onready var team2_list = get_node(team2_list) #as VBoxContainer?
export(NodePath) onready var ip_addr_label = get_node(ip_addr_label) #as Label
export(NodePath) onready var spectators_list = get_node(spectators_list) #as ItamList
onready var no_spectators_label = spectators_list.get_node("NoSpectators") #as Label
export(NodePath) onready var watch_button = get_node(watch_button) #as Button
export(NodePath) onready var start_button = get_node(start_button) #as Button

var player_template: Node
var team1_empty: Node
var team2_empty: Node

func _ready():
	player_template = team1_list.get_node("Player")
	player_template.visible = false
	
	team2_empty = team2_list.get_node("Empty")
	team2_empty.visible = false
	team1_empty = team2_empty.duplicate(0)
	team1_list.add_child(team1_empty)
	
	team1_empty.get_node(@"Join").connect("pressed", self, "_on_Join_pressed", [Types.Team.Team1])
	team2_empty.get_node(@"Join").connect("pressed", self, "_on_Join_pressed", [Types.Team.Team2])
	watch_button.connect("pressed", self, "_on_Join_pressed", [Types.Team.Spectators])
	
	Lobby.connect("connected", self, "_on_Game_connected")
	Lobby.connect("joined", self, "_on_Game_joined")
	Lobby.connect("switched", self, "_on_Game_switched")
	
	ip_addr_label.text = Lobby.get_ip()

func _on_Game_connected():
	game_name_label.text = Game.game_name
	map_size_type_label.text = Types.map2str[Game.map] + " | " + str(Game.team_size) + "x" + str(Game.team_size) + " | " + Types.type2str[Game.type]
	
	for player in Game.clients.values():
		add_player_to_list(player)
	update_buttons()

	get_parent().enable_step(2)

var spectators_list_indeces := []
func add_player_to_list(player):
	
	if player.team == Types.Team.Spectators:
		spectators_list.add_item(player.name, null, false)
		spectators_list_indeces.append(player.id)
		return
	
	var new_entry = player_template.duplicate(0)
	new_entry.get_node(@"Name").text = player.name
	new_entry.name = str(player.id)
	
	var team_list: Node
	if player.team == Types.Team.Team1:
		team_list = team1_list
	elif player.team == Types.Team.Team2:
		team_list = team2_list
		
	team_list.add_child(new_entry)
	team_list.move_child(new_entry, team_list.get_child_count() - 2)
	new_entry.visible = true

func remove_player_from_list(player):
	
	if player.team == Types.Team.Spectators:
		var idx := spectators_list_indeces.find(player.id)
		spectators_list.remove_item(idx)
		spectators_list_indeces.remove(idx)
		return
	
	if player.team == Types.Team.Team1:
		team1_list.get_node(str(player.id)).queue_free()
	elif player.team == Types.Team.Team2:
		team2_list.get_node(str(player.id)).queue_free()

func update_buttons():
	
	var s1 = Game.team1.size()
	var s2 = Game.team2.size()
	var id := get_tree().get_network_unique_id()
	
	var team = null
	if Game.players.has(id):
		team = Game.players[id].team
	
	# ещё не в команде и [ в ней мало людей или переход не создаст перевеса ]
	team1_empty.visible = team != Types.Team.Team1 && (s1 < s2 || (s1 == s2 && team != Types.Team.Team2))
	team2_empty.visible = team != Types.Team.Team2 && (s2 < s1 || (s1 == s2 && team != Types.Team.Team1))
	watch_button.visible = team != Types.Team.Spectators
	start_button.disabled = !get_tree().is_network_server() || Game.players.size() < 1

	no_spectators_label.visible = spectators_list.get_item_count() == 0

func _on_Join_pressed(team):
	Lobby.join(team)

func _on_Game_joined(player: Dictionary):
	add_player_to_list(player)
	update_buttons()

func _on_Game_switched(player_id: int, team_from, team_to):
	remove_player_from_list({ "id": player_id, "name": "", "team": team_from })
	add_player_to_list(Game.clients[player_id])
	update_buttons()

func _on_Game_leaved(player: Dictionary):
	remove_player_from_list(player)
	update_buttons()
	
func _on_Start_pressed():
	Lobby.start()
