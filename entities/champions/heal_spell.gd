class_name HealSpell
extends ActionBase

class HealBuff extends Effect:
	
	func get_name():
		return "heal_buff"
	
	var _heal_amount = 90
	func _init(heal_amount):
		_heal_amount = heal_amount
		_duration = 1#sec
	
	var timer: SceneTreeTimer
	
	func _apply(to):
		._apply(to)
		timer = to.get_tree().create_timer(_duration)
		timer.connect("timeout", self, "_dispel")
		apply_or_stack(self)

	func _stack(with):
		._stack(with)
		apply_or_stack(with)

	func apply_or_stack(with):
		timer.time_left = with._duration
		var heal_amount = with._heal_amount
		if applied_to.effects.has("heal_debuff"):
			heal_amount /= 2
		applied_to.sync_set("health", min(applied_to.health + heal_amount, applied_to.health_max))
		applied_to.movement_speed_multiplier += 0.3
		applied_to.recalculate_speed()

	func _dispel():
		applied_to.movement_speed_multiplier -= 0.3
		applied_to.recalculate_speed() #TODO: recalculate automatially?
		._dispel()

#TODO: move timer to Effect
class HealDebuff extends Effect:
	
	func get_name():
		return "heal_debuff"
		
	var timer: SceneTreeTimer
	func _init():
		_duration = 35#sec
	
	func _apply(to):
		._apply(to)
		timer = to.get_tree().create_timer(_duration)
		timer.connect("timeout", self, "_dispel")
		
	func _stack(with):
		._stack(with)
		timer.time_left = with._duration

func activate(_arg):
	put_on_cooldown()
	var buff = HealBuff.new(90)
	buff.apply(caster)
	var debuff = HealDebuff.new()
	debuff.apply(caster)
	
