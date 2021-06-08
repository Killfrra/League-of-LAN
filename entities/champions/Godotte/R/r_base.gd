class_name RBase
extends CanvasItem

var caster

export var cost := 100.0
export var cooldown := 130
export var charges := 3
export var recast_cooldown := 1.0
export var activation := 10.0

enum State {
	Ready,
	BetweenRecasts,
	Active,
	Cooldown,
}
var state = State.Ready

func can_be_activated():
	return (state == State.Ready and caster.mana >= cost) || state == State.Active

var time_passed_scince_activation := 0.0
var time_passed_scince_recast := 0.0
var remaining_casts: int

func activate(arg = null):
	match state:
		State.Ready:
			_activate(arg)
			remaining_casts = charges - 1
			time_passed_scince_activation = 0
			time_passed_scince_recast = 0
			caster.mana -= cost
			state = State.BetweenRecasts
			_active_enable()
			_recast_enable()
			set_process(true)
		State.Active:
			_activate(arg)
			remaining_casts -= 1
			time_passed_scince_recast = 0
			if remaining_casts > 0:
				state = State.BetweenRecasts
				_recast_enable()
			else:
				_active_disable()
				time_passed_scince_activation = 0
				state = State.Cooldown
				_cooldown_enable()

func _activate(arg = null):
	pass

func _process(delta):
	if state == State.BetweenRecasts:
		time_passed_scince_recast += delta
		if time_passed_scince_recast >= recast_cooldown:
			_recast_disable()
			state = State.Active
		else:
			_recast_update()
	if state == State.Active || state == State.BetweenRecasts:
		time_passed_scince_activation += delta
		if time_passed_scince_activation >= activation:
			time_passed_scince_activation -= activation
			if state == State.BetweenRecasts:
				_recast_disable()
			_active_disable()
			state = State.Cooldown
			_cooldown_enable()
		else:
			_active_update()
	elif state == State.Cooldown:
		time_passed_scince_activation += delta
		if time_passed_scince_activation >= cooldown:
			_cooldown_disable()
			state = State.Ready
		else:
			_cooldown_update()

func _recast_enable():
	pass
func _recast_update():
	pass
func _recast_disable():
	pass
	
func _active_enable():
	pass
func _active_update():
	pass
func _active_disable():
	pass

func _cooldown_enable():
	pass
func _cooldown_update():
	pass
func _cooldown_disable():
	pass
