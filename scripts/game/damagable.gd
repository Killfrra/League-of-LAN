class_name Damagable
extends AvatarOwner

const SIZE_MULTIPLIER := 1.0

var invulnerable := 0
var untargetable := 0

var health
export var health_max := 526.0
export var health_regen := 5.5
export var armor := 20.88
export var mr := 30.0

export var granted_exp := 32.0
export var granted_gold := 14

signal killed_by(killer)
signal damaged_by(damager)

var gameplay_radius: float

func generate_variable_attributes():
	.generate_variable_attributes()
	var_attrs["health"] = Attrs.UNRELIABLE | Attrs.VISIBLE_TO_EVERYONE
	var_attrs["health_max"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["health_regen"] = Attrs.VISIBLE_TO_OWNER_AND_SPEC
	var_attrs["armor"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["mr"] = Attrs.VISIBLE_TO_EVERYONE

func _pre_ready():
	._pre_ready()
	health = health_max
	
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
	
	var damage = true_d + physic_d * calc_damage(armor) + magic_d * calc_damage(mr)
	sync_set("health", max(0, health - damage))

	#	print("damagable.gd:32 ", self)
	from.emit_signal("hit_on_target", self)
	
	if health <= 0:
		
		untargetable += 1
		#print(name, " is dead!")
		
		emit_signal("killed_by", from)
		grant_gold_and_exp(from)
		killed_by(from)
		
	else:
		emit_signal("damaged_by", from)
		damaged_by(from)

func grant_gold_and_exp(to):
	#TODO: move to killed_by?
	if to.is_class("Player"):
		to.set_expirience(to.expirience + granted_exp * 0.93)
		to.sync_set("gold", to.gold + granted_gold)

func killed_by(killer):
	destroy_self()

func damaged_by(killer):
	pass

func _physics_process(delta):
	if health < health_max:
		sync_set("health", min(health + health_regen / 5.0 * delta, health_max))
		if health >= health_max:
			fully_restored()

func fully_restored():
	pass
