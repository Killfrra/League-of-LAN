class_name TurretAvatar
extends SelectableAvatar

export(NodePath) onready var turret = get_node(turret)
var tween: Tween

func _ready():
	tween = Tween.new()
	add_child(tween)

func pack_initials(for_own_team: bool):
	return {
		"owner_team": avatar_owner.team,
		"global_position": avatar_owner.global_position
	}

func init(data):
	.unpack(data)
	$Light2D.enabled = !should_disable_light()
	if should_change_color():
		$Turrel.texture = preload("res://sprites/towerDefense_tile250.png")

func head_to(to, time_to_fire):
	rpc_id(0, "remote_head_to", to, time_to_fire)

var target
#var angle_from
#var angle_to
#var time_remaining
#var time_passed
#var rotating := false
puppetsync func remote_head_to(to, time_to_fire):
	target = get_node(to)
	#angle_from = turret.global_rotation
	#angle_to = turret.global_position.angle_to_point(target.global_position)
	#time_remaining = time_to_fire
	#time_passed = 0
	#rotating = true

func _process(delta):
	if target:
		if is_instance_valid(target):
			turret.look_at(target.global_position)
		else:
			target = null
			print("turret_avatar.gd:45 saved (approved?)")
	#if rotating:
	#	time_passed += delta
	#	if time_passed <= time_remaining:
	#		var t = time_passed / time_remaining
	#		turret.global_rotation = lerp_angle(angle_from, angle_to, t)
	#	else:
	#		rotating = false
	#elif target && is_instance_valid(target):
	#	turret.global_rotation = turret.global_position.angle_to_point(target.position)
