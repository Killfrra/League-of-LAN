class_name Action
extends CanvasItem

export var _name: String
export var cost: float
export var cooldown: float
export var cast_time: float
var remaining_cooldown: float = 0
var remaining_cast_time: float = 0

export var charges := 1
export var time_between_recasts := 1.0
export var activation_time := 0.0
export var channeling_time := 0.0
var remaining_time_between_recasts := 0.0
var remaining_activation_time := 0

#export(NodePath) onready
var caster setget set_caster
# = get_node(caster)

export(NodePath) onready var icon = get_node(icon)
export(NodePath) onready var cooldown_bar = get_node(cooldown_bar)
export(NodePath) onready var cooldown_label = get_node(cooldown_label)
export(NodePath) onready var cost_label = get_node(cost_label) if cost_label else null
export(NodePath) onready var blast_zone = get_node(blast_zone) if blast_zone else null
export(NodePath) onready var cast_bar = get_node(cast_bar) if cast_bar else null
export(NodePath) onready var cast_label = get_node(cast_label) if cast_label else null

export(NodePath) onready var charges_label = get_node(charges_label) if charges_label else null
export(NodePath) onready var activation_bar = get_node(activation_bar) if activation_bar else null

enum KeyList {
	Q = KEY_Q,
	W = KEY_W,
	E = KEY_E,
	R = KEY_R,
	D = KEY_D,
	F = KEY_F,
#	_1 = KEY_1,
#	_2 = KEY_2,
#	_3 = KEY_3,
	_4 = KEY_4,
#	_5 = KEY_5,
#	_6 = KEY_6,
#	_7 = KEY_7,
	B = KEY_B,
}
export(KeyList) var key = KeyList.Q

enum Requires {
	None, Position, Direction
}
export(Requires) var requires

func _ready():
	(icon as TextureRect).self_modulate = Color.white
	(cooldown_label as Label).visible = false
	if blast_zone:
		blast_zone.visible = false
	if cost_label:
		cost_label.text = String(cost)
	cooldown_bar.value = 0

func set_caster(to):
	#print(name, '.caster = ', to.name)
	caster = to
	var grp = caster.create_new_group()
	caster.connect_stat(grp, "mana", self, "on_caster_mana_changed")

var low_on_mana = false
onready var original_texture = (icon as TextureRect).texture
func on_caster_mana_changed(to):
	#if !remaining_cast_time && !remaining_cooldown &&
	if to < cost && !low_on_mana:
		low_on_mana = true
		(icon as TextureRect).texture = preload("res://entities/champions/water-drop.png")
	elif to >= cost && low_on_mana:
		low_on_mana = false
		(icon as TextureRect).texture = original_texture

func begin_casting():
	(cast_label as Label).text = _name
	(cast_bar as ProgressBar).value = 0
	(cast_bar as ProgressBar).visible = true
	remaining_cast_time = cast_time

func put_on_cooldown():
	(icon as TextureRect).self_modulate = Color(0.33, 0.33, 0.33, 1)
	(cooldown_label as Label).visible = true
	(cooldown_bar as TextureProgress).value = 100
	remaining_cooldown = cooldown

func _process(delta):
	if remaining_cast_time > 0:
		remaining_cast_time -= delta
		if remaining_cast_time <= 0:
			remaining_cast_time = 0
			(cast_bar as ProgressBar).visible = false
			on_casting_finished()
		(cast_bar as ProgressBar).value = (1.0 - remaining_cast_time / cast_time) * 100.0
			
	if remaining_cooldown > 0:
		remaining_cooldown -= delta
		if remaining_cooldown <= 0:
			remaining_cooldown = 0
			(icon as TextureRect).self_modulate = Color.white
			(cooldown_label as Label).visible = false
		cooldown_bar.value = (remaining_cooldown / cooldown) * 100
		(cooldown_label as Label).text = String(int(remaining_cooldown) + 1)
		
#	if remaining_time_between_recasts > 0:
#		remaining_time_between_recasts -= delta
#		if remaining_time_between_recasts <= 0:
#			pass
#		pass

func can_be_activated():
	return !remaining_cooldown and caster.mana >= cost

func _input(event: InputEvent):
	#TODO: uncomment?
	#if !get_tree().is_input_handled() and
	if event is InputEventKey:
		if event.scancode == key and can_be_activated():
			if requires == Requires.Direction:
				if blast_zone:
					blast_zone.visible = event.pressed
				if !event.pressed:
					var dir = (caster as Node2D).get_local_mouse_position()
					print(caster.global_position, dir)
					activate(dir)
			elif event.pressed:
				if requires == Requires.Position:
						if blast_zone:
							blast_zone.visible = true
						Events.selection_state = Events.SelectionState.Position
						var pos = yield(Events, "selected")
						Events.selection_state = Events.SelectionState.None
						if blast_zone:
							blast_zone.visible = false
						activate(pos)
				else: #if requires == Requires.None
					activate()
			get_tree().set_input_as_handled()

func activate(arg = null):
	caster.activate(name.to_lower(), arg)
	#print(name, " activated")
	if cast_time:
		begin_casting()
	else:
		on_casting_finished()

func on_casting_finished():
	
	caster.mana -= cost
	if cooldown:
		put_on_cooldown()
	
