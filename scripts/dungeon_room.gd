class_name DungeonRoom
extends RefCounted

var id: int
var role: String
var position: Vector2
var size: Vector2
var custom_name := ""
var connections: Array[int] = []
var connections_by_side: Dictionary = {}
var connection_cells_by_side: Dictionary = {}
var content := "None"
var defeated := false
var combat_hp := -1

func _init(room_id: int, room_role: String, rect_position: Vector2, rect_size: Vector2):
	id = room_id
	role = room_role
	position = rect_position
	size = rect_size

func rect() -> Rect2:
	return Rect2(position, size)

func display_name() -> String:
	if role == "Entrance": return "입구방"
	if role == "Treasure": return "보물방"
	return "일반 방"

func content_name() -> String:
	match content:
		"Treasure": return "보물"
		"Spike": return "가시"
		"Poison": return "독물"
		"Fire": return "불구덩이"
		"Slime", "WeakMonster": return "약한 몬스터"
		"MidMonster": return "중간 몬스터"
		"StrongMonster": return "강한 몬스터"
		_: return ""

func label() -> String:
	var detail := content_name()
	if detail == "": detail = display_name()
	if custom_name != "": detail = custom_name
	return detail
