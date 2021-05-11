class_name Monster
extends Moving

onready var base_location := global_position
var patience := 6
var distance_traveled := 0.0
var patience_tick_timer: Timer

func _ready():
	team = Types.Team.Spectators
	
	patience_tick_timer = Timer.new()
	patience_tick_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
	patience_tick_timer.wait_time = 1
	#patience_tick_timer.one_shot = false
	patience_tick_timer.connect("timeout", self, "decrease_patience", [ 0.5 ])
	connect("moved", self, "on_moved")
	connect("hit_on_target", self, "on_damaging_target")
	add_child(patience_tick_timer)

func damaged_by(damager):
	if not strict_equality(target, base_location):
		if target == null:
			patience_tick_timer.start()
			#print("timer started")
		elif damager != target:
			decrease_patience(1)
			
		if !damager.untargetable:
			set_target(damager)
		#elif typeof(damager) == TYPE_OBJECT && (!is_instance_valid(damager) || (damager as Node).is_queued_for_deletion()):
		#	print("monster.gd:31 saved")
		
		
func decrease_patience(amount):
	patience -= amount
	print(patience)
	if patience <= 0:
		patience_tick_timer.stop()
		#print("timer stopped")
		head_home()

func try_to_find_target_in_area(area): # если противник убит или точка достигнута
	if strict_equality(target, base_location): # если вернулись на базу
		patience = 6
		health_regen = 0
		distance_traveled = 0
		set_target(null)
	else:
		head_home()

func on_moved():
	if patience_tick_timer.is_stopped():
		patience_tick_timer.start()
		#print("timer restarted")
	distance_traveled += global_position.distance_to(prev_pos)
	if distance_traveled >= 700:
		head_home() # направляемся домой

func head_home():
	patience_tick_timer.stop()
	health_regen = health_max / (distance_traveled / move_speed)
	set_target(base_location)
	
func on_damaging_target(_target):
	if !patience_tick_timer.is_stopped():
		patience_tick_timer.stop()
		#print("timer stopped")
