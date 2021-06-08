extends AvatarOwner
class_name Kiss

var sender: Player
var target: Vector2
var damage

var speed := 1550.0

#TODO: deduplicate with orb

func _ready():
	
	assert(Lobby.local_client.id == 1)
	
	var layer = Types.team2vision_layers[Types.Team.Team1] | Types.team2vision_layers[Types.Team.Team2]
	$GameplayRadius.collision_layer = layer
	$GameplayRadius.collision_mask = layer
	
	layer = Types.team2gameplay_layers[Lobby.opposite_team[sender.team]]
	$EffectRadius.collision_layer = layer
	$EffectRadius.collision_mask = layer
	
	$EffectRadius.connect("area_entered", self, "on_effect_area_entered")

var first_frame := true
func _physics_process(delta: float):
	
	if first_frame:
		first_frame = false
		return
	
	var step_length := speed * delta
	
	var step_dir := (target - global_position).normalized()
	var distance := global_position.distance_to(target)
	if step_length >= distance:
		global_position += step_dir * distance
		sync_position()
		destroy_self()
	else:
		#print(step_dir, ' ', step_length, ' ', global_position)
		global_position += step_dir * step_length
		sync_position()

func on_effect_area_entered(area: Area2D):
	if !is_queued_for_deletion():
		var area_parent: Damagable = area.get_parent()
		if area_parent.is_class("Moving"):
			var effect = CharmEffect.new(sender, 1.4, 0.65)
			effect.apply(area_parent)
		area_parent.take_damage(sender, 0, damage, 0)
		destroy_self()
