class_name SelectableAvatar
extends Avatar

func _ready():
	$SelectionRadius.connect("input_event", self, "on_mouse_input")
	$SelectionRadius.connect("mouse_entered", self, "on_mouse_entered")
	$SelectionRadius.connect("mouse_exited", self, "on_mouse_exited")

func on_mouse_input(viewport: Object, event: InputEvent, shape_idx: int):
	if Events.is_left_mouse_keyup(event): # && !get_tree().is_input_handled():
		Events.register_click(self)

var under_cursor := false

func on_mouse_entered():
	#print("mouse entered ", name)
	Events.ignore_ground += 1
	under_cursor = true

func on_mouse_exited():
	#print("mouse exited ", name)
	Events.ignore_ground -= 1
	under_cursor = false

func destroy():
	Events.ignore_ground -= int(under_cursor)
	.destroy()

var owner_team

func should_disable_light():
	return Lobby.local_client.team != Types.Team.Spectators && Lobby.local_client.team != owner_team
	
func should_change_color(): # относительные командные цвета
	if Lobby.local_client.team == Types.Team.Spectators:
		return owner_team == Types.Team.Team2
	return Lobby.local_client.team != owner_team
