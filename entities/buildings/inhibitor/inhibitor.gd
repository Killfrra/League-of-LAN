class_name Inhibitor
extends Damagable

export(Array, NodePath) var protects
var protected_nodes := []

func _ready():
	for path in protects:
		var node = get_node(path)
		node.invulnerable += 1
		node.untargetable += 1
		protected_nodes.append(node)

func killed_by(killer):
	invulnerable += 1
	untargetable += 1
	for protected in protected_nodes:
		protected.invulnerable -= 1
		protected.untargetable -= 1

func fully_restored():
	invulnerable -= 1
	untargetable -= 1
	for protected in protected_nodes:
		if is_instance_valid(protected):
			protected.invulnerable += 1
			protected.untargetable += 1
		else:
			print("inhibitor.gd:27 saved (approved)")
