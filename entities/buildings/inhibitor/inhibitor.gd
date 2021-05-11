class_name Inhibitor
extends Damagable

export(Array, NodePath) var protects

func _ready():
	for i in range(protects.size()):
		protects[i] = get_node(protects[i])
		protects[i].invulnerable = true
		protects[i].untargetable = true

func killed_by(killer):
	invulnerable = true
	untargetable = true
	for protected in protects:
		protected.invulnerable = false
		protected.untargetable = false

func fully_restored():
	invulnerable = false
	untargetable = false
	for protected in protects:
		if is_instance_valid(protected):
			protected.invulnerable = true
			protected.untargetable = true
		else:
			print("inhibitor.gd:27 saved (approved)")
