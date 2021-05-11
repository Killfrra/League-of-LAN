#global Lobby
extends Node

const SERVER_PORT := 10567 # [1024;49151]
const SERVER_MAX_CLIENTS := 4095

var username: String
var local_client: Dictionary
var last_used_runes_and_spells := [
	Types.Rune.Sorcery,
	Types.Spell.Heal,
	Types.Spell.Flash
]

signal logged_in(username)
signal connected()
#signal disconnected()
signal error(e)
signal joined(player)
signal switched(id, from, to)
#signal leaved(player)
signal started(my_team_choices)
signal spell_set()
signal player_ready()
signal final_countdown(sec)
signal loading_screen(opposite_team_choices)
signal spawn()

func _ready():
	get_tree().connect("network_peer_connected", self, "_on_network_peer_connected")
	
func login(uname):
	self.username = username
	emit_signal("logged_in", username)
	
func connect_to(server_ip: String):
	var peer: = NetworkedMultiplayerENet.new()
	if peer.create_client(server_ip, SERVER_PORT) == OK:
		get_tree().network_peer = peer
	else:
		emit_signal("error", "Failed to connect to the server")

func host(game_name: String, team_size: int, map, type):
	var peer = NetworkedMultiplayerENet.new()
	peer.server_relay = false
	#var max_players := team_size * 2 + 4#spec
	if peer.create_server(SERVER_PORT, SERVER_MAX_CLIENTS) == OK:
		get_tree().network_peer = peer
		Game.game_name = game_name
		Game.team_size = team_size
		Game.map = map
		Game.type = type
		local_client = Game.create_peer(1, Types.Team.Team1, username)
		Game.add_peer_to_lists(local_client)
		
		emit_signal("connected")
	else:
		emit_signal("error", "Failed to create server")

func _on_network_peer_connected(id: int):
	if id != 1:
		rpc_id(id, "connected", Game.serialize_room_info())
	
puppet func connected(info):
	Game.deserialize_room_info(info)
	emit_signal("connected")
	
puppet func error(e: String):
	emit_signal("error", e)

func join(team):
	var already_joined = !local_client.empty()
	if already_joined:
		rpc_id(1, "proc_switching_req", team)
	else:
		rpc_id(1, "proc_join_req", team, username)

master func proc_join_req(team, uname: String):
	var id := get_tree().get_rpc_sender_id()
	var already_joined = Game.clients.has(id)
	if !already_joined:
		var peer = Game.create_peer(id, team, uname)
		rpc_id(0, "joined", peer)
	
puppetsync func joined(client):
	Game.add_peer_to_lists(client)
	if client.id == get_tree().get_network_unique_id():
		local_client = client
	emit_signal("joined", client)

master func proc_switching_req(team):
	var id := get_tree().get_rpc_sender_id()
	var player = Game.clients.get(id, null)
	if player != null && player.team != team:
		rpc_id(0, "switched", id, team)

puppetsync func switched(id: int, team):
	var prev_team = Game.switch_peer_team(id, team)
	emit_signal("switched", id, prev_team, team)

var team_choices = {
	Types.Team.Team1: {},
	Types.Team.Team2: {},
	Types.Team.Spectators: {} # linked to Team1 and Team2
}
var my_team_choices

func start():
	
	if local_client.id != 1:
		return # call only on server
	
	for player in Game.players.values():
		var template := { "champion": Types.Champion.Godotte }
		var player_choices = template.duplicate()
		team_choices[player.team][player.id] = player_choices
		team_choices[Types.Team.Spectators][player.id] = player_choices
		
	for client in Game.clients.values():
		rpc_id(client.id, "started", team_choices[client.team])
		
	#get_tree().refuse_new_network_connections = true

puppetsync func started(team_preliminary_choices):
	team_choices[local_client.team] = team_preliminary_choices
	my_team_choices = team_preliminary_choices
	emit_signal("started", my_team_choices)

func set_rune(rune):
	last_used_runes_and_spells[0] = rune
	rpc_id(1, "proc_set_rune_req", rune)
	
master func proc_set_rune_req(rune):
	var id = get_tree().get_rpc_sender_id()
	var player = Game.players[id]
	team_choices[player.team][id].rune = rune

func set_spell(spell, right: bool):
	last_used_runes_and_spells[1 + int(right)] = spell
	rpc_id(1, "proc_set_spell_req", spell, right)
	
master func proc_set_spell_req(spell, right):
	var id = get_tree().get_rpc_sender_id()
	var player = Game.players[id]
	team_choices[player.team][id][["lspell", "rspell"][int(right)]] = spell
	rpc_id(0, "spell_set", id, spell, right)
	
puppetsync func spell_set(id, spell, right):
	if local_client.id != 1:
		my_team_choices[id][["lspell", "rspell"][int(right)]] = spell
	emit_signal("spell_set", id, spell, right)
	
func set_ready():
	rpc_id(1, "proc_set_ready_req")

var players_ready = 0
const opposite_team := {
	Types.Team.Team1 : Types.Team.Team2,
	Types.Team.Team2 : Types.Team.Team1,
	Types.Team.Spectators: Types.Peer.Player
}
master func proc_set_ready_req():
	var id := get_tree().get_rpc_sender_id()
	var team = Game.players[id].team
	#TODO: check if not already ready, champion set and notifications comes not from the spectator
	var player_choices = team_choices[team][id]
	
	if !player_choices.has("ready") && team != Types.Team.Spectators:
		rpc_id(0, "player_ready", id)
		players_ready += 1
		if players_ready == Game.players.size():
			var sec := 1
			
			rpc_id(0, "final_countdown", sec)
			#yield(get_tree().create_timer(sec), "timeout")
			
			for player in Game.players.values():
				rpc_id(player.id, "loading_screen", team_choices[opposite_team[player.team]])
			for spectator in Game.spectators.values():
				rpc_id(spectator.id, "loading_screen", {})
				
			sync_time()

puppetsync func player_ready(id):
	#Game.add_player_info_to_team_data(id, { "ready": true })
	emit_signal("player_ready", id)

puppetsync func final_countdown(sec: int):
	emit_signal("final_countdown", sec)
	
puppetsync func loading_screen(opposite_team_choices):
	if local_client.id == 1 || local_client.team == Types.Team.Spectators:
		my_team_choices = team_choices[Types.Team.Spectators]
	else:
		team_choices[opposite_team[local_client.team]] = opposite_team_choices
		for player in Game.players.values():
			team_choices[Types.Team.Spectators][player.id] = team_choices[player.team][player.id]
		my_team_choices = team_choices[Types.Team.Spectators]
		
	emit_signal("loading_screen")

signal time_resp_arrived(player_time)
#signal time_sync_finished()

const sec_to_server_time_mul := 1000000
const max_interpolation_delay := 0.2 * sec_to_server_time_mul

#var time_synced := false
var server_time_offset = 0
var interpolation_delay = 0 # one for everyone
#var min_round_trip_time := -1
var max_round_trip_time := 0
func sync_time():
	
	assert(local_client.id == 1)
	
	for i in range(5):
		for client in Game.clients.values():
			
			if client.id == 1:
				continue
			
			var req_time = OS.get_ticks_usec()
			rpc_id(client.id, "proc_time_req")
			var client_time = yield(self, "time_resp_arrived")
			var resp_arrival_time = OS.get_ticks_usec()
			var round_trip_time = resp_arrival_time - req_time
			if !client.has("min_round_trip_time") || round_trip_time < client.min_round_trip_time: # == -1:
				client.min_round_trip_time = round_trip_time
				client.server_time_offset = client_time + (client.min_round_trip_time / 2) - resp_arrival_time
				print("server_time_offset for ", client.id, " = ", client.server_time_offset)
			elif client.team != Types.Team.Spectators && (round_trip_time > max_round_trip_time):
				max_round_trip_time = round_trip_time
	
	var interval_between_physics_frames := float(sec_to_server_time_mul) / float(Engine.iterations_per_second)
	interpolation_delay = max_interpolation_delay #clamp(max_round_trip_time, interval_between_physics_frames, max_interpolation_delay)
	print("interpolation_delay for everyone = ", interpolation_delay)
	for client in Game.clients.values():
		if client.id != 1:
			rpc_id(client.id, "adjust_time_and_spawn", -client.server_time_offset, interpolation_delay)
	
	#time_synced = true
	#emit_signal("time_sync_finished")
	#TODO: should I pass team_choices here?
	#TODO: rename
	emit_signal("spawn", my_team_choices)

puppetsync func proc_time_req():
	rpc_id(1, "handle_time_resp", OS.get_ticks_usec())

master func handle_time_resp(player_time):
	emit_signal("time_resp_arrived", player_time)

func get_server_time_with_interpolation_offset():
	return OS.get_ticks_usec() + server_time_offset - interpolation_delay

puppet func adjust_time_and_spawn(serv_time_off, interp_delay):
	server_time_offset = serv_time_off
	interpolation_delay = interp_delay
	emit_signal("spawn", my_team_choices)

func get_ip():
	var addresses := IP.get_local_addresses()
	addresses.invert()
	print(addresses)
	for addr in addresses:
		if (addr as String).count('.') == 3:
			return addr
	return "127.0.0.1"
