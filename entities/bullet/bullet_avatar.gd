class_name BulletAvatar
extends Avatar

func pack_initials(for_own_team: bool):
	return {
		#"owner_team": avatar_owner.sender.team,
		"global_position": avatar_owner.global_position,
		"positions": [
			[ OS.get_ticks_usec(), avatar_owner.global_position ] # or Lobby.get_...
		]
	}
