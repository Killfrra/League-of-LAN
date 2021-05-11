class_name Bullet
extends AvatarOwner

const SIZE_MULTIPLIER := 1.0

var true_damage := 0
var magic_damage := 0
var physic_damage := 0
export(float) var speed := 1200

var sender: Node2D
var target: Damagable

func _ready():
	
	assert(Lobby.local_client.id == 1)
	
	#print(sender.global_position, ' ', global_position)
	
	var layer = Types.team2vision_layers[Types.Team.Team1] | Types.team2vision_layers[Types.Team.Team2]
	$GameplayRadius.collision_layer = layer
	$GameplayRadius.collision_mask = layer

func _physics_process(delta: float):
	
	assert(Lobby.local_client.id == 1)
	
	if is_instance_valid(target):
		
		var step_length: float = delta * speed * SIZE_MULTIPLIER
		var step_dir: Vector2 = (target.global_position - global_position).normalized()
		var distance := global_position.distance_to(target.global_position) - target.gameplay_radius
		
		if step_length >= distance:
			global_position += step_dir * distance
			target.take_damage(sender, true_damage, magic_damage, physic_damage)
			print("37:", global_position)
			update_position()
			avatar.destroy()
			#queue_free()
		else:
			global_position += step_dir * step_length
			#avatar.sync_set_unreliable("global_position", global_position)
			#print(global_position)
			print("45:", global_position)
			update_position()
	else:
		#print("bullet.gd:36 saved (approved)")
		#update_position()
		avatar.destroy()
