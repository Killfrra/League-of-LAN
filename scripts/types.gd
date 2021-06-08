#global Types
extends Node

enum Peer { Spectator, Team1, Team2, Player, Client, Team1_and_Spectators, Team2_and_Spectators }
enum Team { Spectators, Team1, Team2 }
enum Map { SummonersRift, HowlingAbyss }
enum Type { BlindPick, DraftPick  }
enum Spell { Heal, Ghost, Barrier, Exhaust, Mark, Clarity, Flash, Teleport, Smite, Cleanse, Ignite }
enum Rune { Inspiration, Precision, Domination, Resolve, Sorcery }
enum Champion { Godotte }

const map2str = {
	Map.SummonersRift: "Summoner's rift",
	Map.HowlingAbyss: "Howling abyss"
}

const type2str = {
	Type.BlindPick: "blind pick",
	Type.DraftPick: "draft pick"
}

const rune2str = {
	Rune.Inspiration: "Inspiration",
	Rune.Precision: "Precision",
	Rune.Domination: "Domination",
	Rune.Resolve: "Resolve",
	Rune.Sorcery: "Sorcery"
}

const champ2str = {
	Champion.Godotte: "Godotte"
}

const team2vision_layers = {
	Team.Team1: 2,
	Team.Team2: 4,
	Team.Spectators: 2 + 4
}

const team2gameplay_layers = {
	Team.Team1: 8,
	Team.Team2: 16,
	Team.Spectators: 8 + 16
}

const team2vision_blocking_layer = {
	Team.Team1: 32,
	Team.Team2: 64,
	Team.Spectators: 32 + 64
}

# walkaround for intersect_shape bug (detects non-monitorable areas)
const champion_layer = {
	Team.Team1: 128,
	Team.Team2: 256
}
