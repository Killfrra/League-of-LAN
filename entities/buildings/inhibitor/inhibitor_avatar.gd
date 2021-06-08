class_name InhibitorAvatar
extends DamagableAvatar

func init(data):
	.init(data)
	if should_change_color():
		$Crystal.self_modulate = Color(1, 0.329412, 0.329412)
