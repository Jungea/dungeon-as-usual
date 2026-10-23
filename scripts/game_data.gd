class_name GameData
extends RefCounted

const HERO_HP := 20
const HERO_ATTACK := 4
const SPIKE_DAMAGE := 5
const POISON_DAMAGE := 7
const FIRE_DAMAGE := 10
const SLIME_HP := 8
const SLIME_ATTACK := 2
const MID_MONSTER_HP := 14
const MID_MONSTER_ATTACK := 3
const STRONG_MONSTER_HP := 20
const STRONG_MONSTER_ATTACK := 4
const WEAK_MONSTER_ENERGY_COST := 1
const MID_MONSTER_ENERGY_COST := 3
const STRONG_MONSTER_ENERGY_COST := 8
const DEATH_ENERGY := 10

static func room_color(room_type: String) -> Color:

	match room_type:
		"Entrance": return Color("#4ecdc4")
		"Treasure": return Color("#ffd166")
		"Spike": return Color("#ef476f")
		"Slime": return Color("#80ed99")
		"WeakMonster": return Color("#80ed99")
		"MidMonster": return Color("#7cc8ff")
		"StrongMonster": return Color("#c77dff")
		_: return Color("#8da9c4")

static func room_name(room_type: String) -> String:
	match room_type:
		"Entrance": return "입구"
		"Empty": return "빈 방"
		"Spike": return "가시 함정"
		"Slime", "WeakMonster": return "약한 몬스터"
		"MidMonster": return "중간 몬스터"
		"StrongMonster": return "강한 몬스터"
		"Treasure": return "보물"
		_: return room_type
