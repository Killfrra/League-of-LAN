extends AvatarOwner
class_name Orb

var sender: Player
var target: Vector2
var damage

var returning := false

func _ready():
	
	assert(Lobby.local_client.id == 1)
	
	#print(sender.global_position, ' ', global_position)
	
	var layer = Types.team2vision_layers[Types.Team.Team1] | Types.team2vision_layers[Types.Team.Team2]
	$GameplayRadius.collision_layer = layer
	$GameplayRadius.collision_mask = layer
	
	layer = Types.team2gameplay_layers[Lobby.opposite_team[sender.team]]
	$EffectRadius.collision_layer = layer
	$EffectRadius.collision_mask = layer
	
	$EffectRadius.connect("area_entered", self, "on_effect_area_entered")

var speed := 1550.0

var first_frame := true
func _physics_process(delta: float):
	
	if first_frame:
		first_frame = false
		return
	
	var step_length := speed * delta
	
	if returning:
		var step_dir := (sender.global_position - global_position).normalized()
		var distance := global_position.distance_to(sender.global_position)
		if step_length >= distance:
			global_position += step_dir * distance
			sync_position()
			destroy_self()
		else:
			global_position += step_dir * step_length
			speed = min(speed + 1900 * delta, 2600) 
			sync_position()
	else:
		var step_dir := (target - global_position).normalized()
		var distance := global_position.distance_to(target)
		if step_length >= distance:
			global_position += step_dir * distance
			speed = 60
			returning = true
		else:
			#print(step_dir, ' ', step_length, ' ', global_position)
			global_position += step_dir * step_length
		sync_position()

func on_effect_area_entered(area: Area2D):
	var area_parent: Damagable = area.get_parent()
	#if area_parent:
	if returning:
		area_parent.take_damage(sender, damage, 0, 0)
	else:
		area_parent.take_damage(sender, 0, damage, 0)
