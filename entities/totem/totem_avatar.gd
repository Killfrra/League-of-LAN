class_name TotemAvatar
extends DamagableAvatar

func init(data):
	.init(data)
	$Light2D.enabled = !should_disable_light()
