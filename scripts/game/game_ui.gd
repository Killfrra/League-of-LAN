class_name GameUI
extends Control

export(NodePath) onready var shared_panel = get_node(shared_panel)
export(NodePath) onready var kda_label = get_node(kda_label)
export(NodePath) onready var cs_label = get_node(cs_label)
export(NodePath) onready var time_label = get_node(time_label)
export(NodePath) onready var fps_label = get_node(fps_label)
export(NodePath) onready var ping_label = get_node(ping_label)

var ticker
func _ready():
	ticker = Timer.new()
	ticker.connect("timeout", self, "update_clock")
	add_child(ticker)
	
	Lobby.connect("spawn", self, "on_Game_spawn")
	Events.connect("show_info", shared_panel, "attach")
	
	Lobby.connect("game_ended", self, "on_game_ended")
	$Victory/Button.connect("button_down", self, "on_continue_button_down")
	#TODO: remove ofc
	$InstantWin1.connect("button_down", Lobby, "end_game", [Types.Team.Team1])
	$InstantWin2.connect("button_down", Lobby, "end_game", [Types.Team.Team2])

	set_process(false)
	#set_process_input(false)

func on_Game_spawn(team_choices):
	
	shared_panel.visible = false
	$Victory.visible = false
	
	get_parent().enable_step(4)
	ticker.start()
	ping_label.text = String(floor(Lobby.interpolation_delay / Lobby.sec_to_server_time_mul * 1000)) + " ms"
	set_process(true)

func update_clock():
	var sec_passed = int((Lobby.current_time - Game.start_time) / Lobby.sec_to_server_time_mul)
	time_label.text = "%02d:%02d" % [sec_passed / 60, sec_passed % 60]

func _process(delta):
	fps_label.text = String(Engine.get_frames_per_second())

func on_game_ended(winner_team):
	var we_won = Lobby.local_client.team == winner_team
	if we_won:
		$Victory/Button.self_modulate = Color(1, 1.75, 2)
		$Victory/Panel/Label.text = "VICTORY"
		$Victory/Panel/TopLine.self_modulate = Color(0.5, 0.87, 1)
		$Victory/Panel/BotLine.self_modulate = Color(0.5, 0.87, 1)
	else:
		$Victory/Button.self_modulate = Color(2, 1, 1)
		$Victory/Panel/Label.text = "DEFEAT"
		$Victory/Panel/TopLine.self_modulate = Color(1, 0.5, 0.5)
		$Victory/Panel/BotLine.self_modulate = Color(1, 0.5, 0.5)
	$Victory.visible = true
	$Victory.mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_filter = Control.MOUSE_FILTER_PASS
	#set_process_input(true)
	
	set_process(false)

export(NodePath) onready var camera = get_node(camera)

func on_continue_button_down():
	#TODO: move to camera?
	camera.get_parent().remove_child(camera)
	$"/root/Control".add_child(camera)
	
	$"/root/Spawned".queue_free()
	get_parent().enable_step(2)

	var game_ui = $"/root/Control/GUI/PageSwitcher/Page5_GameUI" #TODO: fix absolute path
	var panel = game_ui.get_node("CenterPanel")
	panel.queue_free()

	#TODO: move to Lobby
	for player in Game.players.values():
		player.ready = false

	mouse_filter = Control.MOUSE_FILTER_IGNORE

#func _input(event):
#	get_tree().set_input_as_handled()
