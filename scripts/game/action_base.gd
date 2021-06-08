class_name ActionBase
extends CanvasItem

#TODO: deduplicate with action_button

export var cost: float
export var cooldown: float
export var cast_time: float
var remaining_cooldown: float = 0
var remaining_cast_time: float = 0

var caster setget set_caster

func set_caster(to):
	caster = to

#func begin_casting():
#	remaining_cast_time = cast_time
	
func put_on_cooldown():
	remaining_cooldown = cooldown

func _process(delta):
#	if remaining_cast_time > 0:
#		remaining_cast_time -= delta
#		if remaining_cast_time <= 0:
#			remaining_cast_time = 0
#			on_casting_finished()
#		on_casting_step()
			
	if remaining_cooldown > 0:
		remaining_cooldown -= delta
		if remaining_cooldown <= 0:
			remaining_cooldown = 0
			on_cooldown_finished()
		on_cooldown_step()
		
#func on_casting_finished():
#	pass
#
#func on_casting_step():
#	pass

func on_cooldown_finished():
	pass
	
func on_cooldown_step():
	pass

func can_be_activated():
	return !caster.casting_disallowed && !caster.casting && !remaining_cooldown && caster.mana >= cost
	
func activate(arg):
	pass
#	if can_be_activated():
#		if cast_time:
#			begin_casting()
#		else:
#			on_casting_finished()
