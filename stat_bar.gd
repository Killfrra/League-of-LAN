class_name StatBar
extends ProgressBar

export(NodePath) onready var label = get_node(label)
export(NodePath) onready var regen_label = get_node(regen_label) if regen_label else null

var prev_label_value := 0.0
var value_regen := 0.0

func update_text(new_value):
	if regen_label:
		regen_label.visible = new_value != max_value
	label.text = String(floor(new_value)) + " / " + String(floor(max_value))
	prev_label_value = new_value

func set_value(new_value):
	.set_value(new_value)
	
	if (max_value - new_value) <= value_regen:
		update_text(max_value)
	elif abs(new_value - prev_label_value) >= value_regen:
		update_text(new_value)

func set_regen(to):
	#TODO: 1s vs 5s?
	value_regen = to / 5.0
	if regen_label:
		regen_label.text = "+" + String(stepify(to, 0.1))
