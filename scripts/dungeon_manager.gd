class_name DungeonManager
extends RefCounted

const MIN_ROOM_SIZE := Vector2(96, 96)
const DEFAULT_ROOM_SIZE := Vector2(160, 96)
const ROOM_MARGIN := 32.0
const GRID_SIZE := 32.0

var rooms: Dictionary = {}
var next_id := 1

func reset() -> void:
	rooms.clear()
	next_id = 1

func add_room(role: String, rect_position: Vector2, rect_size: Vector2 = DEFAULT_ROOM_SIZE) -> DungeonRoom:
	var room := DungeonRoom.new(next_id, role, rect_position, rect_size.max(MIN_ROOM_SIZE))
	if _overlaps_existing(room.rect()): return null
	rooms[next_id] = room
	next_id += 1
	return room

func remove_room(id: int) -> void:
	if not rooms.has(id): return
	rooms.erase(id)
	for other in rooms.values():
		other.connections.erase(id)
		for side in other.connections_by_side.keys():
			if other.connections_by_side[side] == id: other.connections_by_side.erase(side)

func room_at(point: Vector2) -> DungeonRoom:
	var room_list: Array = rooms.values()
	room_list.reverse()
	for room in room_list:
		if room.rect().has_point(point): return room
	return null

func move_room(id: int, new_position: Vector2) -> bool:
	if not rooms.has(id): return false
	var room: DungeonRoom = rooms[id]
	var old := room.position
	room.position = new_position
	if _overlaps_existing(room.rect(), id):
		room.position = old
		return false
	_refresh_connection_sides()
	return true

func resize_room(id: int, new_size: Vector2) -> bool:
	if not rooms.has(id): return false
	var room: DungeonRoom = rooms[id]
	var old := room.size
	room.size = new_size.max(MIN_ROOM_SIZE)
	if _overlaps_existing(room.rect(), id):
		room.size = old
		return false
	_refresh_connection_sides()
	return true

func _refresh_connection_sides() -> void:
	for room in rooms.values(): room.connections_by_side.clear()
	for room in rooms.values():
		for other_id in room.connections:
			if other_id > room.id and rooms.has(other_id):
				var other: DungeonRoom = rooms[other_id]
				var side := _side_for(room, other)
				room.connections_by_side[side] = other_id
				other.connections_by_side[_opposite(side)] = room.id
				if not room.connection_cells_by_side.has(side): room.connection_cells_by_side[side] = _middle_cell(room, side)
				if not other.connection_cells_by_side.has(_opposite(side)): other.connection_cells_by_side[_opposite(side)] = _middle_cell(other, _opposite(side))

func _overlaps_existing(target: Rect2, ignored_id := -1) -> bool:
	for id in rooms:
		if id != ignored_id and rooms[id].rect().grow(ROOM_MARGIN).intersects(target.grow(ROOM_MARGIN)):
			return true
	return false

func _side_for(first: DungeonRoom, second: DungeonRoom) -> String:
	var delta := second.position + second.size / 2.0 - (first.position + first.size / 2.0)
	if abs(delta.x) >= abs(delta.y): return "RIGHT" if delta.x >= 0 else "LEFT"
	return "BOTTOM" if delta.y >= 0 else "TOP"

func _opposite(side: String) -> String:
	match side:
		"RIGHT": return "LEFT"
		"LEFT": return "RIGHT"
		"BOTTOM": return "TOP"
		_: return "BOTTOM"

func side_point(room: DungeonRoom, side: String) -> Vector2:
	var center := room.position + room.size / 2.0
	match side:
		"RIGHT": return Vector2(room.position.x + room.size.x, center.y)
		"LEFT": return Vector2(room.position.x, center.y)
		"BOTTOM": return Vector2(center.x, room.position.y + room.size.y)
		_: return Vector2(center.x, room.position.y)

func connect_rooms(a_id: int, b_id: int) -> bool:
	return connect_rooms_on_sides(a_id, b_id, "", "")

func connect_rooms_on_sides(a_id: int, b_id: int, requested_first_side: String, requested_second_side: String, first_cell: int = -1, second_cell: int = -1) -> bool:
	if a_id == b_id or not rooms.has(a_id) or not rooms.has(b_id): return false
	var first: DungeonRoom = rooms[a_id]
	var second: DungeonRoom = rooms[b_id]
	if b_id in first.connections: return false
	var first_side := requested_first_side if requested_first_side != "" else _side_for(first, second)
	var second_side := requested_second_side if requested_second_side != "" else _opposite(first_side)
	if first.connections_by_side.has(first_side) or second.connections_by_side.has(second_side): return false
	first.connections.append(b_id)
	second.connections.append(a_id)
	first.connections_by_side[first_side] = b_id
	second.connections_by_side[second_side] = a_id
	first.connection_cells_by_side[first_side] = _middle_cell(first, first_side) if first_cell < 0 else first_cell
	second.connection_cells_by_side[second_side] = _middle_cell(second, second_side) if second_cell < 0 else second_cell
	return true

func _middle_cell(room: DungeonRoom, side: String) -> int:
	var count := int(room.size.y / GRID_SIZE) if side == "LEFT" or side == "RIGHT" else int(room.size.x / GRID_SIZE)
	return max(0, count / 2)

func side_cell_point(room: DungeonRoom, side: String, cell: int) -> Vector2:
	match side:
		"RIGHT": return Vector2(room.position.x + room.size.x, room.position.y + (cell + 0.5) * GRID_SIZE)
		"LEFT": return Vector2(room.position.x, room.position.y + (cell + 0.5) * GRID_SIZE)
		"BOTTOM": return Vector2(room.position.x + (cell + 0.5) * GRID_SIZE, room.position.y + room.size.y)
		_: return Vector2(room.position.x + (cell + 0.5) * GRID_SIZE, room.position.y)

func touching_room_on_side(room_id: int, side: String) -> int:
	if not rooms.has(room_id): return -1
	var room: DungeonRoom = rooms[room_id]
	var target := room.rect()
	for other_id in rooms:
		if other_id == room_id: continue
		var other: DungeonRoom = rooms[other_id]
		var other_rect: Rect2 = other.rect()
		var touching := false
		var overlap := 0.0
		if side == "RIGHT" or side == "LEFT":
			var edge := target.end.x if side == "RIGHT" else target.position.x
			var other_edge := other_rect.position.x if side == "RIGHT" else other_rect.end.x
			touching = abs(edge - other_edge) <= ROOM_MARGIN * 2.0 + 2.0
			overlap = min(target.end.y + ROOM_MARGIN, other_rect.end.y + ROOM_MARGIN) - max(target.position.y - ROOM_MARGIN, other_rect.position.y - ROOM_MARGIN)
		else:
			var edge_y := target.end.y if side == "BOTTOM" else target.position.y
			var other_edge_y := other_rect.position.y if side == "BOTTOM" else other_rect.end.y
			touching = abs(edge_y - other_edge_y) <= ROOM_MARGIN * 2.0 + 2.0
			overlap = min(target.end.x + ROOM_MARGIN, other_rect.end.x + ROOM_MARGIN) - max(target.position.x - ROOM_MARGIN, other_rect.position.x - ROOM_MARGIN)
		if touching and overlap > 4.0: return other_id
	return -1

func disconnect_rooms(a_id: int, b_id: int) -> void:
	if not rooms.has(a_id) or not rooms.has(b_id): return
	var first: DungeonRoom = rooms[a_id]
	var second: DungeonRoom = rooms[b_id]
	first.connections.erase(b_id)
	second.connections.erase(a_id)
	for side in first.connections_by_side.keys():
		if first.connections_by_side[side] == b_id:
			first.connections_by_side.erase(side)
			first.connection_cells_by_side.erase(side)
	for side in second.connections_by_side.keys():
		if second.connections_by_side[side] == a_id:
			second.connections_by_side.erase(side)
			second.connection_cells_by_side.erase(side)

func validation_message() -> String:
	var entrance_count := 0
	var entrance_id := -1
	var treasure_ids: Array[int] = []
	for id in rooms:
		if rooms[id].role == "Entrance":
			entrance_count += 1
			entrance_id = id
		if rooms[id].role == "Treasure": treasure_ids.append(id)
	if entrance_count != 1: return "입구방을 정확히 1개 설정해야 합니다."
	if treasure_ids.size() != 1: return "보물방을 정확히 1개 설정해야 합니다."
	var queue: Array[int] = [entrance_id]
	var seen := {entrance_id: true}
	while not queue.is_empty():
		var current: int = queue.pop_front()
		if current in treasure_ids: return ""
		for next_id in rooms[current].connections:
			if not seen.has(next_id):
				seen[next_id] = true
				queue.append(next_id)
	return "입구방에서 보물방까지 연결된 통로가 없습니다."
