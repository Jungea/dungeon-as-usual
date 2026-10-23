class_name DungeonManager
extends RefCounted

var rooms: Dictionary = {}
var next_id := 1

func reset() -> void:
	rooms.clear()
	next_id = 1
	add_room("Entrance", Vector2(220, 360))

func add_room(kind: String, pos: Vector2) -> DungeonRoom:
	var room := DungeonRoom.new(next_id, kind, pos)
	rooms[next_id] = room
	next_id += 1
	return room

func remove_room(id: int) -> void:
	if not rooms.has(id) or rooms[id].room_type == "Entrance":
		return
	rooms.erase(id)
	for room in rooms.values():
		room.connections.erase(id)

func connect_rooms(a: int, b: int) -> bool:
	if a == b or not rooms.has(a) or not rooms.has(b):
		return false
	var first: DungeonRoom = rooms[a]
	var second: DungeonRoom = rooms[b]
	if b in first.connections:
		return false
	first.connections.append(b)
	second.connections.append(a)
	return true

func disconnect_rooms(a: int, b: int) -> void:
	if rooms.has(a): rooms[a].connections.erase(b)
	if rooms.has(b): rooms[b].connections.erase(a)

func entrance_id() -> int:
	for id in rooms:
		if rooms[id].room_type == "Entrance": return id
	return -1

func treasure_id() -> int:
	for id in rooms:
		if rooms[id].room_type == "Treasure": return id
	return -1

func path_to_treasure() -> bool:
	var start := entrance_id()
	var goal := treasure_id()
	if start < 0 or goal < 0: return false
	var queue: Array[int] = [start]
	var seen := {start: true}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current == goal: return true
		for next_id in rooms[current].connections:
			if not seen.has(next_id):
				seen[next_id] = true
				queue.append(next_id)
	return false

func validation_message() -> String:
	if entrance_id() < 0: return "입구가 필요합니다."
	if treasure_id() < 0: return "보물방이 필요합니다."
	if not path_to_treasure(): return "입구에서 보물방까지 연결된 길이 없습니다."
	return ""
