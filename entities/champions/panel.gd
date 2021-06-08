class_name StatsPanel
extends CanvasItem

export(NodePath) onready var health_bar = get_node(health_bar)
export(NodePath) onready var mana_bar = get_node(mana_bar)

export(NodePath) var stats_container
onready var stats = get_node(stats_container).get_children()
export(NodePath) onready var level_label = get_node(level_label)
export(NodePath) onready var kda_label = get_node(kda_label) if kda_label else null
export(NodePath) onready var cs_label = get_node(cs_label) if cs_label else null

export(NodePath) onready var effect_template = get_node(effect_template)
export(NodePath) onready var buff_container = get_node(buff_container)
export(NodePath) onready var debuff_container = get_node(debuff_container)

func _ready():
	#TODO: level is just a stat?
	stats.append(level_label)
	if cs_label:
		stats.append(cs_label)
		
	effect_template.get_parent().remove_child(effect_template)
	#effect_template.visible = false

var attached_to
var connections_group
func attach(to):

	if attached_to:
		deattach()
	attached_to = to

	to.connect("destroyed", self, "on_observed_destroyed")

	connections_group = to.create_new_group()
	
	to.connect_stat(connections_group, "health_max", health_bar, "set_max")
	to.connect_stat(connections_group, "health_regen", health_bar, "set_regen")
	to.connect_stat(connections_group, "health", health_bar, "set_value")

	if to.id == Lobby.local_client.id:
		health_bar.self_modulate = Color(1, 2, 1) # green
	elif DamagableAvatar.should_I_change_color_if_my_team_is(to.team):
		health_bar.self_modulate = Color(2, 1, 1) # red
	else:
		health_bar.self_modulate = Color(1, 1.75, 2) # blue
	
	if "mana" in to:
		to.connect_stat(connections_group, "mana_max", mana_bar, "set_max")
		to.connect_stat(connections_group, "mana_regen", mana_bar, "set_regen")
		to.connect_stat(connections_group, "mana", mana_bar, "set_value")
		mana_bar.self_modulate = Color(1, 1.75, 2)
		mana_bar.label.visible = true
	else:
		mana_bar.label.visible = false
		mana_bar.value = 0
		mana_bar.self_modulate = Color(
			1.0 + (62.0 - 56.0) / 255.0,
			1.0 + (62.0 - 54.0) / 255.0,
			1.0 + (62.0 - 58.0) / 255.0
		)
		#60, 58, 68 <- enabled button
		#62, 62, 62 <- disabled button
		#56, 54, 58 <- enabled bar
	
	if kda_label: # teoretically impossible
		if "kills" in to || "deaths" in to || "assists" in to:
			to.connect_stat(connections_group, "kills", self, "update_kda")
			to.connect_stat(connections_group, "deaths", self, "update_kda")
			to.connect_stat(connections_group, "assists", self, "update_kda")
			kda_label.visible = true
		else:
			kda_label.visible = false
			
	if cs_label:
		cs_label.visible = "creep_score" in to
	
	for i in range(stats.size()):
		var stat = stats[i]
		if stat.name in to:
			#print("conecting stat ", stat.name)
			to.connect_stat(connections_group, stat.name, self, "set_stat_by_id", [ i ])
		else:
			stat.text = "0"
	
	to.remove_outdated_effects()
	for effect_data in to.effects.values():
		add_effect(effect_data)

	to.connect("effect_applied", self, "add_effect")
	#to.connect("effect_duration_set")
	#to.connect("effect_stacks_set")
	to.connect("effect_dispelled", self, "remove_effect")

	visible = true

func on_observed_destroyed():
	attached_to = null #deattach()
	visible = false
	clear_effects()

func update_kda(_v):
	kda_label.text = String(attached_to.kills) + "/" + String(attached_to.deaths) + "/" + String(attached_to.assists)

func set_stat_by_id(new_value, id):
	#print("updating stat ", stats[id].name, " = ", new_value)
	
	if new_value < 1 && new_value != 0:
		new_value = stepify(new_value, 0.01)
	else:
		new_value = round(new_value)
		
	stats[id].text = String(new_value)

var effect_icons = {
	"heal_buff": preload("res://icons/speedometer.png"),
	"heal_debuff": preload("res://icons/health-decrease.png"),
	"charm_debuff": preload("res://icons/charm.png"),
}
var effects := {} # data -> ui
func add_effect(data):
	var effect = effect_template.duplicate(DUPLICATE_SCRIPTS)
	var name: String = data.name
	effect.name = name
	effect.texture = effect_icons[name]
	effects[name] = effect
	var container = buff_container if name.find("debuff") == -1 else debuff_container
	container.add_child(effect)
	effect.init(data)
	effect.visible = true

func remove_effect(name):
	effects[name].queue_free()
	effects.erase(name)

func deattach():
	attached_to.disconnect("destroyed", self, "on_observed_destroyed")
	attached_to.disconnect_group(connections_group)
	
	attached_to.disconnect("effect_applied", self, "add_effect")
	#attached_to.disconnect("effect_duration_set")
	#attached_to.disconnect("effect_stacks_set")
	attached_to.disconnect("effect_dispelled", self, "remove_effect")
	clear_effects()

func clear_effects():
	for effect in effects.values():
		effect.queue_free()
	effects.clear()
