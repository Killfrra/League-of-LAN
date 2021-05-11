class_name InhibitorAvatar
extends SelectableAvatar

#TODO: same as in turret_avatar.gd

func pack_initials(for_own_team: bool):
	return {
		"owner_team": avatar_owner.team,
		"global_position": avatar_owner.global_position
	}

func init(data):
	.unpack(data)
	if should_change_color():
		$Crystal.self_modulate = Color(1, 0.329412, 0.329412)
