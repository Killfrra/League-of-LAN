#TODO: rename to Champion
class_name Player
extends Moving

func is_class(name: String):
	return name == "Player" || .is_class(name)

var mana
export var mana_max: float = 418.0
export var mana_regen: float = 8.0

export var ability_power := 9.0
export var ability_haste := 0.0

#TODO:
var stacks
var crit_damage := 1.75
var strike_chance := 0.0

#TODO: rename to using_abilities_...
var casting_disallowed := 0

export var level_int := 1
var level_frac
var exp_to_next_level := 280

var expirience := 0.0 setget set_expirience
func set_expirience(to):
	expirience = to
	if expirience > exp_to_next_level:
		expirience -= exp_to_next_level
		exp_to_next_level += 100
		level_up_stats()
		sync_set("level_int", level_int + 1)
	level_frac = expirience / exp_to_next_level
	sync_set("level_frac")

func level_up_stats():
	# damagable
	var health_change = 92 * (0.65 + 0.035 * level_int)
	sync_set("health_max", health_max + health_change)
	sync_set("health_regen", health_regen + 0.06 * (0.65 + 0.035 * level_int))
	sync_set("health", min(health + health_change, health_max))
	
	sync_set("armor", armor + 3.5 * (0.65 + 0.035 * level_int))
	sync_set("mr", mr + 0.5 * (0.65 + 0.035 * level_int))
	# autoattacking
	sync_set("attack_damage", attack_damage + 3 * (0.65 + 0.035 * level_int))
	# champion
	var mana_change = 92 * (0.65 + 0.035 * level_int)
	sync_set("mana_max", mana_max + 25 * (0.65 + 0.035 * level_int))
	sync_set("mana_regen", mana_regen + 0.08 * (0.65 + 0.035 * level_int))
	sync_set("mana", min(mana + mana_change, mana_max))
	#TODO: sync_vars({})

export var gold := 500.0
var creep_score := 0
var kills := 0
var deaths := 0
var assists := 0

func generate_variable_attributes():
	.generate_variable_attributes()
	var_attrs["mana"] = Attrs.UNRELIABLE | Attrs.VISIBLE_TO_EVERYONE
	var_attrs["mana_max"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["mana_regen"] = Attrs.VISIBLE_TO_OWNER_AND_SPEC
	var_attrs["ability_power"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["ability_haste"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["strike_chance"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["level_int"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["level_frac"] = Attrs.VISIBLE_TO_OWNER_AND_SPEC
	var_attrs["gold"] = Attrs.VISIBLE_TO_OWNER_AND_SPEC
	var_attrs["kills"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["deaths"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["assists"] = Attrs.VISIBLE_TO_EVERYONE
	var_attrs["creep_score"] = Attrs.VISIBLE_TO_EVERYONE

func _pre_ready():
	._pre_ready()
	level_frac = 0.0
	mana = mana_max
	
func _ready():
	
	$Actions/Q.caster = self
	$Actions/W.caster = self
	$Actions/E.caster = self
	$Actions/F.caster = self
	
	$GameplayRadius.collision_layer |= Types.champion_layer[team]
	#$GameplayRadius.collision_mask |= Types.champion_layer[team]

func _physics_process(delta):

	if mana < mana_max:
		sync_set("mana", min(mana + mana_regen / 5.0 * delta, mana_max))

onready var vision_radius: float = $SightRadius/CollisionShape2D.shape.radius

func lock_target(to):
	target_locked = true
	#print("player.gd:9 ", target_locked)
	if typeof(to) != TYPE_OBJECT || is_instance_valid(to) && !to.is_queued_for_deletion() && !to.untargetable && !to.team == team: #TODO: fix invalid instances again?
		.set_target(to)

#TODO: вынести fire_* в отдельные классы или ноды
func activate(action, arg):
	match action:
		"q":
			$Actions/Q.activate(arg)
		"w":
			$Actions/W.activate(arg)
		"e":
			$Actions/E.activate(arg)
		"f":
			$Actions/F.activate(arg)
		"4":
			spawn_totem(arg)
		"b":
			pass

export(PackedScene) var totem_prefab: PackedScene

func spawn_totem(pos):
	var totem = totem_prefab.instance()
	totem.team = team
	totem.global_position = pos
	$"/root/Spawned".add_child(totem, true)

var spawn_manager

func killed_by(killer):
	
	global_position = spawn_manager.team_spawn[team].global_position
	set_target(null)
	untargetable -= 1 #TODO: maybe +1?
	casting_disallowed = 0
	sync_set("health", health_max)
	sync_set("mana", mana_max)
	sync_position()

func calc_priority(candidate, victium=null):
	var score = 0
	score += 1 - min(1, candidate.global_position.distance_to(global_position) / vision_radius)
	return score

var casting := false

#TODO: rename booth
var target_of_last_autoattack: Damagable
var was_attacked_in_time: int

func fire():
	.fire()
	target_of_last_autoattack = target
	#print("target_of_last_autoattack is ", target.name)
	was_attacked_in_time = Lobby.get_ticks_msec()
