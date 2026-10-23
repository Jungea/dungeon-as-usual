class_name DungeonHero
extends RefCounted

var hp := GameData.HERO_HP
var current_room := -1
var previous_room := -1
var visited_rooms: Dictionary = {}
var known_connections: Dictionary = {}
var state := "EXPLORING"
var path_stack: Array[int] = []
var rng := RandomNumberGenerator.new()

func _init(start_room: int):
	rng.randomize()
	current_room = start_room
	path_stack.append(start_room)

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
	if path_stack.size() > 1:
		state = "BACKTRACKING"
		path_stack.pop_back()
		return path_stack.back()
	state = "CHOOSING PATH"
	return -1

func move_to(room_id: int) -> void:
	previous_room = current_room
	current_room = room_id
	if room_id != previous_room: path_stack.append(room_id)
	state = "MOVING"
