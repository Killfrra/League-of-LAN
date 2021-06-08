class_name LobbyUI_PageSwitcher
extends Control

#var steps := []
var children: Array

func _ready():
	children = get_children()
	enable_step(0)
	
func enable_step(num: int):
	var i := 0
	for child in children:
		child.visible = i == num
		i += 1
	#print("Step ", num, " enabled")
