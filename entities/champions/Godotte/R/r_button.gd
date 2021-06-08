class_name RButton
extends RBase

export(NodePath) onready var icon = get_node(icon)
export(NodePath) onready var cooldown_bar = get_node(cooldown_bar)
export(NodePath) onready var cooldown_label = get_node(cooldown_label)
export(NodePath) onready var cost_label = get_node(cost_label)
export(NodePath) onready var charges_label = get_node(charges_label)
export(NodePath) onready var activation_bar = get_node(activation_bar)

func _ready():
	icon.self_modulate = Color.white
	cooldown_bar.value = 0
	cooldown_label.visible = false
	cost_label.text = String(cost)
	charges_label.text = String(charges)
	activation_bar.value = 0

func _input(event: InputEvent):
	if event is InputEventKey:
		if event.scancode == KEY_R and can_be_activated():
			if !event.pressed:
				var dir = (caster as Node2D).get_local_mouse_position()
				print(caster.global_position, dir)
				activate(dir)
			get_tree().set_input_as_handled()

func _activate(arg = null):
	caster.activate(name.to_lower(), arg)

func _recast_enable():
	icon.self_modulate = Color(0.33, 0.33, 0.33, 1)
	cooldown_bar.value = 100
	charges_label.text = String(remaining_casts)
	cooldown_label.visible = true
	
func _recast_update():
	var time_remaining = recast_cooldown - time_passed_scince_recast
	cooldown_bar.value = (time_remaining / recast_cooldown) * 100
	cooldown_label.text = String(stepify(time_remaining, 0.1) + 0.1)

func _recast_disable():
	icon.self_modulate = Color.white
	cooldown_bar.value = 0
	cooldown_label.visible = false

func _active_enable():
	activation_bar.value = 100
	
func _active_update():
	var time_remaining = activation - time_passed_scince_activation
	activation_bar.value = (time_remaining / activation) * 100
	
func _active_disable():
	activation_bar.value = 0

func _cooldown_enable():
	_recast_enable()
	
func _cooldown_update():
	var time_remaining = cooldown - time_passed_scince_activation
	cooldown_bar.value = (time_remaining / cooldown) * 100
	cooldown_label.text = String(int(time_remaining) + 1)

func _cooldown_disable():
	_recast_disable()
	charges_label.text = String(charges)
