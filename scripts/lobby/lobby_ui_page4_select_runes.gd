class_name LobbyUI_Page4_SelectRunes
extends Panel

export(NodePath) onready var left_player_list = get_node(left_player_list) #as VBoxContainer?
export(NodePath) onready var right_player_list = get_node(right_player_list) #as VBoxContainer?
export(NodePath) onready var lockin_button = get_node(lockin_button) #as OptionButton?
export(NodePath) onready var runes_list = get_node(runes_list) #as OptionButton?
export(NodePath) onready var player_only_stuff = get_node(player_only_stuff) #as OptionButton?
var left_list_template
var right_list_template

func _ready():
	left_list_template = left_player_list.get_node(@"Player")
	right_list_template = right_player_list.get_node(@"Player")
	left_list_template.visible = false
	right_list_template.visible = false
	Lobby.connect("started", self, "on_Game_started")
	Lobby.connect("player_ready", self, "on_Game_player_ready")
	
	lockin_button.connect("pressed", self, "on_LockIn_pressed")
	
	for rune in Types.Rune.values():
		runes_list.add_item(Types.rune2str[rune], rune)
	runes_list.connect("item_selected", self, "on_Runes_item_selected")

func left_or_right(team): #TODO: rename
	if Lobby.local_client.team == Types.Team.Spectators:
		return team == Types.Team.Team1
	else:
		return team == Lobby.local_client.team

func on_Game_started(my_team_choices):
	
	for player in Game.players.values():
		var team_list
		var player_template
		
		var player_choices = my_team_choices.get(player.id, {})
		for key in player_choices:
			player[key] = player_choices[key]
		
		if left_or_right(player.team):
			team_list = left_player_list
			player_template = left_list_template
		else:
			team_list = right_player_list
			player_template = right_list_template
	
		var new_entry = player_template.duplicate(0)
		new_entry.get_node(@"Name").text = player.name
		
		var state_node = new_entry.get_node(@"State")
		if player.has("champion"):
			var champion_name = Types.champ2str[player.champion]
			new_entry.get_node(@"Icon").texture = load("res://entities/champions/" + champion_name + "/images/icon.png")
			
			if player.get("ready", false):
				state_node.text = champion_name
			else:
				state_node.text = "Chooses..."
		else:
			state_node.text = "Chooses..."
		
		var spells_known = player.has("lr")
		new_entry.get_node(@"LRune").visible = spells_known
		new_entry.get_node(@"RRune").visible = spells_known
		new_entry.name = str(player.id)
		
		team_list.add_child(new_entry)
		new_entry.visible = true
		
		player_only_stuff.visible = Lobby.local_client.team != Types.Team.Spectators

	get_parent().enable_step(3)

func on_Runes_item_selected(idx: int):
	var rune = runes_list.get_item_id(idx)
	Lobby.set_rune(rune)

func on_LockIn_pressed():
	lockin_button.disabled = true
	Lobby.set_ready()

func on_Game_player_ready(id):
	var team_list
	var player = Game.players[id]
	
	if left_or_right(player.team):
		team_list = left_player_list
	else:
		team_list = right_player_list
	
	var entry = team_list.get_node(str(id))
	var state_node = entry.get_node(@"State")
	if player.has("champion"):
		state_node.text = Types.champ2str[player.champion]
	else:
		state_node.text = "Ready!"
