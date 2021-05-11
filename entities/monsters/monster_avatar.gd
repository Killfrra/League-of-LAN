class_name MonsterAvatar
extends SelectableAvatar

func pack_initials(for_own_team: bool):
	return {
		"global_position": avatar_owner.global_position
	}

func init(data):
	.unpack(data)
