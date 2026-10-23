class_name DungeonHero
extends RefCounted

var hp := GameData.HERO_HP
var current_room := -1
var previous_room := -1
var visited_rooms: Dictionary = {}
var known_connections: Dictionary = {}
var state := "EXPLORING"
var rng := RandomNumberGenerator.new()

func _init(start_room: int):
	rng.randomize()
	current_room = start_room

func enter(room_id: int, connections: Array[int]) -> void:
	previous_room = current_room
	current_room = room_id
	visited_rooms[room_id] = true
	known_connections[room_id] = connections.duplicate()

func choose_next() -> int:
	var known: Array = known_connections.get(current_room, [])
	var unseen: Array[int] = []
	for room_id in known:
		if not visited_rooms.has(room_id): unseen.append(room_id)
	if not unseen.is_empty():
		state = "CHOOSING PATH"
		return unseen[rng.randi_range(0, unseen.size() - 1)]
	var frontier_step := _next_step_to_frontier()
	if frontier_step >= 0:
		state = "BACKTRACKING"
		return frontier_step
	return -1

func _next_step_to_frontier() -> int:
	var queue: Array[int] = [current_room]
	var parent: Dictionary = {current_room: -1}
	var frontier_room := -1
	while not queue.is_empty():
		var room_id: int = queue.pop_front()
		for next_id in known_connections.get(room_id, []):
			if not visited_rooms.has(next_id):
				frontier_room = room_id
				break
			if visited_rooms.has(next_id) and not parent.has(next_id):
				parent[next_id] = room_id
				queue.append(next_id)
		if frontier_room >= 0: break
	if frontier_room < 0: return -1
	var step := frontier_room
	while parent.get(step, -1) != current_room and parent.get(step, -1) >= 0:
		step = parent[step]
	return step

func move_to(room_id: int) -> void:
	previous_room = current_room
	current_room = room_id
	state = "MOVING"
