class_name AutoattackingAvatar
extends DamagableAvatar

var attack_damage := 0.0 setget set_attack_damage
func set_attack_damage(to):
	emit_stat("attack_damage", to)
	attack_damage = to

var attack_speed := 0.0 setget set_attack_speed
func set_attack_speed(to):
	emit_stat("attack_speed", to)
	attack_speed = to
