class_name PlayerAvatar
extends MovingAvatar

var player_info

var mana := 0.0 setget set_mana
func set_mana(to):
	emit_stat("mana", to)
	mana = to

var mana_max := 0.0 setget set_mana_max
func set_mana_max(to):
	emit_stat("mana_max", to)
	mana_max = to

var mana_regen := 0.0 setget set_mana_regen
func set_mana_regen(to):
	emit_stat("mana_regen", to)
	mana_regen = to

var strike_chance := 0.0 setget set_strike_chance
func set_strike_chance(to):
	emit_stat("strike_chance", to)
	strike_chance = to

var ability_power := 0.0 setget set_ability_power
func set_ability_power(to):
	emit_stat("ability_power", to)
	ability_power = to

var ability_haste := 0.0 setget set_ability_haste
func set_ability_haste(to):
	emit_stat("ability_haste", to)
	ability_haste = to

var level_int := 1 setget set_level_int
func set_level_int(to):
	emit_stat("level_int", to)
	level_int = to

var level_frac := 0.0 setget set_level_frac
func set_level_frac(to):
	emit_stat("level_frac", to)
	level_frac = to

var gold := 0.0 setget set_gold
func set_gold(to):
	emit_stat("gold", to)
	gold = to

var kills := 0 setget set_kills
func set_kills(to):
	emit_stat("kills", to)
	kills = to

var deaths := 0 setget set_deaths
func set_deaths(to):
	emit_stat("deaths", to)
	deaths = to

var assists := 0 setget set_assists
func set_assists(to):
	emit_stat("assists", to)
	assists = to

var creep_score := 0.0 setget set_creep_score
func set_creep_score(to):
	emit_stat("creep_score", to)
	creep_score = to

onready var manabar := $Bars/Panel/ManaBar

func sender_is_owner(): #TODO: set node master and get rid of this?
	var sender_id := get_tree().get_rpc_sender_id()
	return sender_id == avatar_owner.id

var game_ui: GameUI
export(NodePath) onready var panel = get_node(panel)
export(NodePath) onready var exp_bar = get_node(exp_bar)
export(NodePath) onready var gold_button = get_node(gold_button)
export(Array, NodePath) var ability_paths
var abilities = {}

func _ready():
	#set_process_input(false)
	#set_process_unhandled_input(false)
	$Abilities/Q/Range.visible = false

func init(data):
	.init(data)
	
	player_info = Game.players[id]
	if Lobby.local_client.id == id:
		Events.connect("set_target", self, "on_target_set")
		
		var camera = $"/root/Control/Camera2D" #TODO: fix absolute path
		camera.get_parent().remove_child(camera)
		add_child(camera)
		camera.position = Vector2.ZERO # Vector2(1280, -720)
		
		#set_process_input(true)
		#set_process_unhandled_input(true)
		
		for path in ability_paths:
			var ability = get_node(path)
			abilities[ability.name.to_lower()] = ability
			ability.caster = self
		
		game_ui = $"/root/Control/GUI/PageSwitcher/Page5_GameUI" #TODO: fix absolute path
		
		panel.get_parent().remove_child(panel)
		game_ui.add_child(panel)

		panel.kda_label = game_ui.kda_label
		panel.stats.append(game_ui.cs_label)
		panel.attach(self)
		connect_stat(panel.connections_group, "level_frac", exp_bar, "set_value")
		connect_stat(panel.connections_group, "gold", self, "update_gold")

		var fpcg = floating_panel_connections_group
		connect_stat(fpcg, "mana_max", manabar, "set_max")
		connect_stat(fpcg, "mana", manabar, "set_value")
		
		healthbar.self_modulate = Color(1, 2, 1) # green
		
	else:
		
		panel.queue_free()
		panel = null
	
	$Bars/Panel/NameLabel.text = player_info.name
	$Bars/Panel/LevelLabel.text = "1"
	$Light2D.enabled = !should_disable_light()

func update_gold(to):
	gold_button.text = "$ " + String(round(to))

func on_target_set(target):
	if typeof(target) == TYPE_VECTOR2:
		rpc_id(1, "set_target", target)
	else:
		rpc_id(1, "set_target", target.get_path())

master func set_target(to):
	#TODO: failsafe
	
	if !sender_is_owner():
		return
	
	#print(name, " set_target ", to)
	if typeof(to) == TYPE_NODE_PATH:
		var local_avatar = get_node_or_null(to)
		if local_avatar == null:
			to = null
		else:
			to = (local_avatar as Avatar).avatar_owner
	elif typeof(to) == TYPE_VECTOR2:
		pass
	else:
		to = null
	avatar_owner.lock_target(to)

func _process(delta):
	#if $Abilities.visible:
	#TODO: move to ActionButton?
	$Abilities.look_at(get_global_mouse_position())

func activate(action, arg):
	#print(action, " activated with arg ", arg)
	rpc_id(1, "proc_activate_req", action, arg)

master func proc_activate_req(action, arg):
	#print(action, " activation req arrived")
	if sender_is_owner():
		avatar_owner.activate(action, arg)
