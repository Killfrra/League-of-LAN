class_name SpawnManager
extends Node

export(PackedScene) var buildings_prefab: PackedScene
export(NodePath) onready var monster_spawn = get_node(monster_spawn)

onready var wave_spawn_timer := Timer.new()
onready var individual_minion_spawn_timer := Timer.new()

export(float) var sec_between_waves := 30

func _ready():
	
	wave_spawn_timer.wait_time = sec_between_waves
	individual_minion_spawn_timer.wait_time = 197.5 / 330 #190-205
	wave_spawn_timer.connect("timeout", self, "spawn_minion_wave")
	
	#wave_spawn_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	#individual_minion_spawn_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	
	add_child(wave_spawn_timer)
	add_child(individual_minion_spawn_timer)
	
	Lobby.connect("spawn", self, "on_Game_spawn")
	Lobby.connect("game_ended", self, "on_game_ended")

func add_node_with_name_to(node, name):
	var new_node = Node.new()
	new_node.name = name
	node.add_child(new_node)
	return new_node

func on_Game_spawn(team_choices):
	
	var root = get_tree().get_root()
	var spawned_root = add_node_with_name_to(root, "Spawned")
	add_node_with_name_to(spawned_root, "Avatars")
	add_node_with_name_to(spawned_root, "Players")
	
	if Lobby.local_client.id != 1:
		return
		
	spawn_champions(team_choices)
	
	var buildings = buildings_prefab.instance()
	spawned_root.add_child(buildings)

	var monster = preload("res://entities/monsters/monster.tscn").instance()
	monster.position = monster_spawn.global_position
	monster.team = Types.Team.Spectators
	spawned_root.add_child(monster)

	#yield(get_tree().create_timer(5), "timeout")
	begin_spawning_minion_waves()
	
export(NodePath) onready var team1_spawn = get_node(team1_spawn)
export(NodePath) onready var team2_spawn = get_node(team2_spawn)
onready var team_spawn := [ null, team1_spawn, team2_spawn ]
var summoned_champion

func spawn_champions(team_choices):
	for player in Game.players.values():
		var prefab = load("res://entities/champions/" + Types.champ2str[team_choices[player.id].champion] + "/prefab.tscn")
		var champ = prefab.instance()
		var spawn_point = team_spawn[player.team].global_position
		
		champ.set_name(str(player.id)) # Use unique ID as node name.
		champ.global_position = spawn_point
		
		champ.id = player.id
		champ.team = player.team
		champ.spawn_manager = self
		$"/root/Spawned/Players".add_child(champ)

		if player.id == Lobby.local_client.id:
			summoned_champion = champ

func begin_spawning_minion_waves():
	wave_spawn_timer.start()
	spawn_minion_wave()

export(PackedScene) var melee_minion_prefab: PackedScene
export(PackedScene) var caster_minion_prefab: PackedScene
export(NodePath) onready var top_line = get_node(top_line) as Line2D
onready var top_line_reverse := duplicate_and_reverse_line(top_line)
export(NodePath) onready var mid_line = get_node(mid_line) as Line2D
onready var mid_line_reverse := duplicate_and_reverse_line(mid_line)
export(NodePath) onready var bot_line = get_node(bot_line) as Line2D
onready var bot_line_reverse := duplicate_and_reverse_line(bot_line)

func duplicate_and_reverse_line(line: Line2D) -> Line2D:
	var new_line: Line2D = line.duplicate(0)
	# next 3 lines will be unnecessary in 4.0
	var reverse_points := new_line.points
	reverse_points.invert()
	new_line.points = reverse_points
	add_child(new_line, true)
	return new_line

var lines_left_to_spawn := 0
func spawn_minion_wave():
	individual_minion_spawn_timer.start()
	lines_left_to_spawn = 1
	spawn_minions_on_lane(mid_line, mid_line_reverse)
	#spawn_minions_on_lane(bot_line, bot_line_reverse)
	
export(int) var minions_in_wave := 6

func spawn_minions_on_lane(line, reverse_line):
	
#	var team1_melee_minions := []
#	var team2_melee_minions := []
	
	for prefab in [melee_minion_prefab, caster_minion_prefab]:
		for _i in range(3):
			#var team1_minion =
			spawn_minion(line, Types.Team.Team1, prefab)
			#var team2_minion =
			spawn_minion(reverse_line, Types.Team.Team2, prefab)
			yield(individual_minion_spawn_timer, "timeout")
	
	lines_left_to_spawn -= 1
	if lines_left_to_spawn == 0:
		individual_minion_spawn_timer.stop()

func spawn_minion(line, team, prefab):
	var new_minion: Minion = prefab.instance()
	new_minion.team = team
	new_minion.global_position = line.points[0]
	new_minion.lane_line = line
	$"/root/Spawned".add_child(new_minion, true)
	return new_minion

func on_game_ended(_winner_team):
	wave_spawn_timer.stop()
	individual_minion_spawn_timer.stop()
