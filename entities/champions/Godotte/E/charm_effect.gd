class_name CharmEffect
extends Effect

var _caster
var _slowdown
func _init(caster, duration, slowdown):
	_caster = caster
	_duration = duration
	_slowdown = slowdown

func get_name():
	return "charm_debuff"

var timer
var target_before_charm
var attack_range_before_charm

var caster_was_unseen := false
func _apply(to):
	._apply(to)
	timer = to.get_tree().create_timer(_duration)
	timer.connect("timeout", self, "_dispel")
	
	to.target_locked = true
	target_before_charm = to.target
	to.set_target(_caster)
	
	attack_range_before_charm = to.attack_range
	to.attack_range = _caster.gameplay_radius + to.gameplay_radius
	
	to.movement_speed_multiplier -= _slowdown
	to.recalculate_speed()
	
	if "casting_disallowed" in to:
		to.casting_disallowed += 1
	if "attacking_disallowed" in to:
		to.attacking_disallowed += 1
	
	#TODO: what if it's victium's personal sight restrictions?
	_caster.connect("in_sight", self, "on_caster_seen")
	_caster.connect("killed_by", self, "on_caster_killed")
	on_caster_seen(null)

#TODO: test these two funcs
func on_caster_seen(by_team):
	if caster_was_unseen:
		caster_was_unseen = false
		applied_to.movement_disallowed -= 1
	elif !_caster.seen_by_teams[applied_to.team]:
		caster_was_unseen = true
		applied_to.movement_disallowed += 1

func on_caster_killed(by):
	#TODO: queue_free timer?
	#timer.stop()
	_dispel()

func _stack(with):
	._stack(with)
	timer.time_left = with._duration
	if _slowdown < with._slowdown:
		applied_to.movement_speed_multiplier -= with._slowdown - _slowdown
		_slowdown = with._slowdown
		applied_to.recalculate_speed()

func _dispel():
	
	if caster_was_unseen:
		applied_to.movement_disallowed -= 1
	
	applied_to.target_locked = false
	
	#TODO: move to Autoattacking.restore_target or smth...
	if target_before_charm && (
		typeof(target_before_charm) == TYPE_VECTOR2 || (
			is_instance_valid(target_before_charm) && !target_before_charm.untargetable
		)
	):
		applied_to.set_target(target_before_charm)
	elif applied_to.acquisition_area:
		applied_to.try_to_find_target_in_area(applied_to.acquisition_area)
	
	applied_to.attack_range = attack_range_before_charm
	
	applied_to.movement_speed_multiplier += _slowdown
	applied_to.recalculate_speed()
	
	if "casting_disallowed" in applied_to:
		applied_to.casting_disallowed -= 1
	if "attacking_disallowed" in applied_to:
		applied_to.attacking_disallowed -= 1

	._dispel()
