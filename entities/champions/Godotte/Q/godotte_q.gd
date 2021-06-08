class_name GodotteQ
extends ActionBase

export(PackedScene) var orb_prefab: PackedScene

func activate(dir):
	if can_be_activated():
		caster.casting = true
		caster.movement_disallowed += 1
		
		yield(get_tree().create_timer(cast_time), "timeout")
		
		dir = dir.normalized()
		
		var orb = orb_prefab.instance()
		orb.sender = caster
		orb.global_position = caster.global_position
		orb.target = caster.global_position + dir * 900
		orb.damage = 40 + 0.35 * caster.ability_power
		$"/root/Spawned".add_child(orb, true)
		#print("Orb spawned: ", orb.is_inside_tree(), " dir: ", dir)
		
		caster.movement_disallowed -= 1
		caster.casting = false
		
		caster.mana -= cost #TODO: merge with put_on_cooldown?
		put_on_cooldown()
