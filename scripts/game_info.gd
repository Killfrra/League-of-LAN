#global Game
extends Node

var game_name: String
var map
var team_size: int
var type

var lists := {}
var clients
var spectators
var players
var team1
var team2
var team1_and_spec
var team2_and_spec

func _enter_tree():
	
	for c in Types.Peer.values():
		lists[c] = {}
	clients = lists[Types.Peer.Client]
	spectators = lists[Types.Peer.Spectator]
	players = lists[Types.Peer.Player]
	team1 = lists[Types.Peer.Team1]
	team2 = lists[Types.Peer.Team2]
	team1_and_spec = lists[Types.Peer.Team1_and_Spectators]
	team2_and_spec = lists[Types.Peer.Team2_and_Spectators]

func create_peer(id, team, username):
	return { "id": id, "team": team, "name": username }

func add_peer_to_lists(peer):
	clients[peer.id] = peer
	if peer.team == Types.Peer.Spectator:
		spectators[peer.id] = peer
	else:
		players[peer.id] = peer
		lists[peer.team][peer.id] = peer

func remove_peer_from_lists(id):
	var peer = clients[id]
	clients.erase(id)
	if peer.team == Types.Peer.Spectator:
		spectators.erase(id)
	else:
		players.erase(id)
		lists[peer.team].erase(id)

	return peer

func switch_peer_team(id, new_team):
	var peer = clients[id]
	var prev_team = peer.team
	if new_team == Types.Peer.Spectator:
		players.erase(id)
		lists[prev_team].erase(id)
		spectators[id] = peer
	elif prev_team == Types.Peer.Spectator:
		spectators.erase(id)
		players[id] = peer
		lists[new_team][id] = peer
	else:
		lists[prev_team].erase(id)
		lists[new_team][id] = peer
	peer.team = new_team
	return prev_team
	
func copy_keys(to_dict: Dictionary, from_dict: Dictionary, keys: Array):
	for key in keys:
		to_dict[key] = from_dict[key]

func serialize_room_info():
	var dict := {}
	for p in [ "game_name", "map", "team_size", "type" ]:
		dict[p] = self[p]
	dict.clients = clients.values()
	return dict

func deserialize_room_info(dict):
	for p in [ "game_name", "map", "team_size", "type" ]:
		self[p] = dict[p]
	for client in dict.clients:
		add_peer_to_lists(client)
