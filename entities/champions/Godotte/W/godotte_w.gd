class_name GodotteW
extends ActionBase

export(PackedScene) var flames_prefab: PackedScene
export(NodePath) onready var fox_fire_area = get_node(fox_fire_area)

func set_caster(to):
	.set_caster(to)
	fox_fire_area.set_team(caster.team)

func activate(_arg):
	#print("fire_w")
	if can_be_activated():

		#print("before instance")
		var flames = flames_prefab.instance()
		#print("after instance")
		flames.sender = caster
		flames.damage = 40 + 0.30 * caster.ability_power
		flames.additional_damage = 12 + 0.09 * caster.ability_power
		caster.add_child(flames, true)
		#flames.position = Vector2.ZERO
		#print("flames_prefab instanced as ", flames.name)
		
		caster.mana -= cost
		put_on_cooldown()
