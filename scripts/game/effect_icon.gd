class_name EffectIcon
extends TextureRect

export(NodePath) var progress_bar
var progress_bar_node
export(NodePath) var stacks_label
var stacks_label_node

var _data
var _duration_left

func _ready():
	progress_bar_node = get_node(progress_bar)
	stacks_label_node = get_node(stacks_label)
	set_process(false)

func init(data):
	_data = data
	var stacks = data.stacks
	var duration = data.duration
	var time_of_applying = data.time_of_applying - Lobby.server_time_offset
	
	if stacks < 0:
		stacks_label_node.visible = false
	else:
		stacks_label_node.text = String(stacks)
	
	if is_inf(duration):
		progress_bar_node.visible = false
	else:
		_duration_left = duration - (Lobby.get_ticks_usec() - time_of_applying) / Lobby.sec_to_server_time_mul
		progress_bar_node.value = 100
		set_process(true)
		
func _process(delta):
	_duration_left -= delta
	if _duration_left <= 0:
		#_duration_left += _data.duration
		progress_bar_node.value = 0
		set_process(false)
		return
	progress_bar_node.value = (_duration_left / _data.duration) * 100
