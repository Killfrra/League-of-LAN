class_name GodotteE
extends ActionBase

export var kiss_prefab: PackedScene

func activate(dir):
	if can_be_activated():
		caster.casting = true
		caster.movement_disallowed += 1
		
		yield(get_tree().create_timer(cast_time), "timeout")
		
		dir = dir.normalized()
		
		var kiss = kiss_prefab.instance()
		kiss.sender = caster
		kiss.global_position = caster.global_position
		kiss.target = caster.global_position + dir * 1000
		kiss.damage = 72 + 0.48 * caster.ability_power
		$"/root/Spawned".add_child(kiss, true)
		
		caster.movement_disallowed -= 1
		caster.casting = false
		
		caster.mana -= cost
		put_on_cooldown()
