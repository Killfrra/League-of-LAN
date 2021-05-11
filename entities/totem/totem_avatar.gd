class_name TotemAvatar
extends SelectableAvatar

#TODO: same as in turret_avatar.gd

func pack_initials(for_own_team: bool):
	return {
		"owner_team": avatar_owner.team,
		"global_position": avatar_owner.global_position
	}

func init(data):
	.unpack(data)
	$Light2D.enabled = !should_disable_light()
