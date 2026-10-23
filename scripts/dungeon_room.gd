class_name DungeonRoom
extends RefCounted

var id: int
var room_type: String
var position: Vector2
var connections: Array[int] = []
var defeated := false
var combat_hp := -1

func _init(room_id: int, kind: String, pos: Vector2):
	id = room_id
	room_type = kind
	position = pos

func label() -> String:
	return "%s\n#%d" % [GameData.room_name(room_type), id]
