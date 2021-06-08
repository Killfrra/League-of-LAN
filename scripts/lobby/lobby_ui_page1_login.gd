class_name LobbyUI_Page1_Login
extends Control

func _on_Enter_pressed():
	var text: String = $Username.text
	_on_Username_text_entered(text)

func _on_Username_text_entered(new_text: String):
	Lobby.login(new_text)
