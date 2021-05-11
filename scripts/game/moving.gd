class_name Moving
extends Autoattacking

const DISTANCE_DELTA := 35 #5

export(float) var move_speed = 330
export(NodePath) onready var body = get_node(body) as RigidBody2D
onready var navmesh: Navigation2D = $"/root/Control/Map/Navigation2D" #TODO: fix absolute path

signal moved()

var path: PoolVector2Array

func _ready():
	body.mode = RigidBody2D.MODE_CHARACTER
	#body.friction = 0

func set_target(to): # to Vector2 or Object or null
	#print(body, " moving ", name, " set_target (", typeof(to), ") ", to)
	if not strict_equality(to, target):
		.set_target(to)
		if target != null:
			recalculate_path()
		else:
			path.resize(0)

func on_target_moved(which):
	#if is_valid_object_to_target(target):
	.on_target_moved(which)
	if path.empty() || target.global_position.distance_squared_to(path[path.size() - 1]) > 15*15:
		recalculate_path()
	#elif typeof(target) == TYPE_OBJECT && (!is_instance_valid(target) || (target as Node).is_queued_for_deletion()):
	#	print("moving.gd:33 saved")

func get_target_position():
	if typeof(target) == TYPE_VECTOR2:
		return target
	if typeof(target) == TYPE_OBJECT:
		return target.global_position

func recalculate_path():
	path = navmesh.get_simple_path(global_position, get_target_position(), true)
	#line.points = path
	path.remove(0)

func perpendicular(vec: Vector2) -> Vector2:
	return Vector2(-vec.y, vec.x)

func is_left(A: Vector2, B: Vector2) -> bool:
	return -A.x * B.y + A.y * B.x < 0

var collision: KinematicCollision2D
func get_collisions() -> Array:
	var ret := []
	var current_collision = collision
	while current_collision and current_collision.collider and ret.find(current_collision) == -1:
		ret.append(current_collision)
		current_collision = current_collision.collider.collision
	return ret

var shifting_frames := 0
var last_collision
#func _physics_process(delta):
var prev_time = 0
func _integrate_forces(state: Physics2DDirectBodyState):
	#var time = float(OS.get_ticks_usec()) / 1000000.0
	#var delta = state.step # time - prev_time
	#prev_time = time
	var body: RigidBody2D = self.body

	if path.size():
		
		#if is_valid_object_to_target(target)
		
		if typeof(target) == TYPE_OBJECT && check_if_target_in_attack_range():
			path.resize(0)
			#print("moving.gd:70 ", target)
			fire_if_possible()
			body.set_linear_velocity(Vector2.ZERO)
			return
		
		#elif typeof(target) == TYPE_OBJECT && (!is_instance_valid(target) || (target as Node).is_queued_for_deletion()):
		#	print("moving.gd:77 saved")
		
		var dist_to_next_point = global_position.distance_to(path[0])
		if dist_to_next_point <= DISTANCE_DELTA:
			path.remove(0)
			#print("point removed")
			#line.remove_point(0)
	
		if path.size():
			var velocity: Vector2 = move_speed * SIZE_MULTIPLIER * (path[0] - position).normalized()
			
			#if shifting_frames == 0:
			#	if collision:
			#		last_collision = collision
			#		shifting_frames = 16
			#	else:
			#		velocity = move_speed * SIZE_MULTIPLIER * (path[0] - position).normalized()
			#if shifting_frames > 0:
			#	velocity = move_speed * last_collision.normal.tangent()
			#	shifting_frames -= 1

			#if collision && !is_left(collision.position - global_position, velocity.tangent()):
			#	velocity = move_speed * collision.normal.tangent()
			#	if team == Types.Team.Team2:
			#		velocity *= -1
					
			#collision = body.move_and_collide(velocity * delta)
			#body.move_and_slide(velocity)
			body.linear_velocity = velocity #* delta * 9.8 * 9.8
			#line.set_point_position(0, global_position)
			
			#emit_signal("moved")
			
		else: # target is point and it is reached
			try_to_find_target_in_area(acquisition_area) # target = null
			target_locked = false
			#print("moving.gd:106 ", target_locked)
			body.set_linear_velocity(Vector2.ZERO)
	else:
		body.set_linear_velocity(Vector2.ZERO)

onready var prev_pos := global_position
func _physics_process(_delta):
	update_position() #TODO: транслировать позицию только при изменении оной
	if global_position != prev_pos:
		emit_signal("moved")
		prev_pos = global_position
