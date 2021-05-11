class_name Damagable
extends AvatarOwner

const SIZE_MULTIPLIER := 1.0

var invulnerable := false
var untargetable := false

export(float) var health_max = 526
onready var health = health_max
export(float) var health_regen = 5.5
export(float) var armor = 20.88
export(float) var mr = 30

signal killed_by(killer)
signal damaged_by(damager)

var gameplay_radius: float

func _ready():
	var layer = Types.team2gameplay_layers[team] | Types.team2vision_layers[team]
	$GameplayRadius.collision_layer = layer
	$GameplayRadius.collision_mask = layer
	gameplay_radius = $GameplayRadius/CollisionShape2D.shape.radius * SIZE_MULTIPLIER

func calc_damage(resist):
	if resist > 0:
		return 100 / (100 + resist)
	else:
		return 2 - (100 / (100 - resist))

func take_damage(from, true_d, magic_d, physic_d):
	if invulnerable || health <= 0:
		return
		
	if !is_instance_valid(from) || from.is_queued_for_deletion():
		#print("damagable.gd:37 saved (approved if called from bullet)")
		return
	
	health -= true_d + physic_d * calc_damage(armor) + magic_d * calc_damage(mr)

	#	print("damagable.gd:32 ", self)
	from.emit_signal("hit_on_target", self)
	
	if health <= 0:
		
		untargetable = true
		#print(name, " is dead!")
		
		emit_signal("killed_by", from)
		killed_by(from)
	else:
		emit_signal("damaged_by", from)
		damaged_by(from)

func killed_by(killer):
	avatar.destroy()

func damaged_by(killer):
	pass

func _process(delta):
	if health < health_max:
		health = min(health + health_regen * delta, health_max)
		if health >= health_max:
			fully_restored()

func fully_restored():
	pass
