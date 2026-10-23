class_name GameData
extends RefCounted

const HERO_HP := 20
const HERO_ATTACK := 4
const SPIKE_DAMAGE := 5
const SLIME_HP := 8
const SLIME_ATTACK := 2
const BOSS_HP := 20
const BOSS_ATTACK := 4
const DEATH_ENERGY := 10

static func room_color(room_type: String) -> Color:

	match room_type:
		"Entrance": return Color("#4ecdc4")
		"Treasure": return Color("#ffd166")
		"Spike": return Color("#ef476f")
		"Slime": return Color("#80ed99")
		"Boss": return Color("#c77dff")
		_: return Color("#8da9c4")

static func room_name(room_type: String) -> String:
	match room_type:
		"Entrance": return "입구"
		"Empty": return "빈 방"
		"Spike": return "가시 함정"
		"Slime": return "슬라임"
		"Boss": return "보스"
		"Treasure": return "보물"
		_: return room_type
