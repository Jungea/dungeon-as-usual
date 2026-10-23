extends Node2D

const ROOM_RADIUS := 38.0
const CANVAS_RECT := Rect2(180, 116, 1070, 565)

var dungeon := DungeonManager.new()
var mode := "EDIT"
var tool := ""
var selected_room := -1
var connect_first := -1
var dragging_room := -1
var hero: DungeonHero
var hero_timer := 0.0
var combat_timer := 0.0
var speed := 1.0
var energy := 0
var entered := 0
var killed := 0
var energy_earned := 0
var rooms_visited := 0
var trap_hits := 0
var event_text := "던전을 설계하고 '던전 영업 시작'을 누르세요."
var result_text := ""
var buttons: Array[Dictionary] = []
var ui_font: Font

func _ready() -> void:
	dungeon.reset()
	ui_font = ThemeDB.fallback_font
	_build_ui()
	queue_redraw()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "오늘도 던전 영업합니다"
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "오늘도 정상 영업 중  •  1차 프로토타입"
	subtitle.position = Vector2(26, 54)
	subtitle.modulate = Color("#8da9c4")
	add_child(subtitle)
	_create_button("빈 방 추가", Vector2(22, 110), "ADD_EMPTY")
	_create_button("가시 함정 추가", Vector2(22, 150), "ADD_SPIKE")
	_create_button("슬라임 추가", Vector2(22, 190), "ADD_SLIME")
	_create_button("보스 추가", Vector2(22, 230), "ADD_BOSS")
	_create_button("보물 추가", Vector2(22, 270), "ADD_TREASURE")
	_create_button("방 연결", Vector2(22, 325), "CONNECT")
	_create_button("연결 삭제", Vector2(22, 365), "DELETE_LINK")
	_create_button("방 삭제", Vector2(22, 405), "DELETE")
	_create_button("던전 영업 시작", Vector2(22, 455), "OPEN")
	_create_button("던전 수정하기", Vector2(22, 500), "RETURN")
	_create_button("x1", Vector2(22, 565), "SPEED_1")
	_create_button("x2", Vector2(78, 565), "SPEED_2")
	_create_button("x4", Vector2(134, 565), "SPEED_4")

func _create_button(text: String, pos: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(140 if text.length() > 3 else 48, 32)
	button.pressed.connect(func(): _button_action(action))
	add_child(button)
	buttons.append({"button": button, "action": action})

func _button_action(action: String) -> void:
	if action.begins_with("SPEED"):
		speed = {"SPEED_1": 1.0, "SPEED_2": 2.0, "SPEED_4": 4.0}[action]
		event_text = "진행 속도 x%d" % int(speed)
		return
	if action == "RETURN":
		mode = "EDIT"
		tool = ""
		result_text = ""
		event_text = "던전을 수정할 수 있습니다."
		_update_buttons()
		queue_redraw()
		return
	if mode == "RUN": return
	if action == "OPEN":
		var error := dungeon.validation_message()
		if error != "":
			event_text = error
		else: _start_run()
		queue_redraw()
		return
	if action == "DELETE":
		if selected_room >= 0:
			dungeon.remove_room(selected_room)
			selected_room = -1
			event_text = "방을 삭제했습니다."
		queue_redraw()
		return
	if action == "DELETE_LINK":
		tool = "DISCONNECT"
		connect_first = -1
		event_text = "삭제할 연결의 첫 번째 방을 클릭하세요."
		return
	if action == "CONNECT":
		tool = "CONNECT"
		connect_first = -1
		event_text = "연결할 첫 번째 방을 클릭하세요."
		return
	tool = action.replace("ADD_", "")
	event_text = "%s을(를) 배치할 위치를 클릭하세요." % GameData.room_name(tool.capitalize())

func _update_buttons() -> void:
	for item in buttons:
		var button: Button = item["button"]
		var action: String = item["action"]
		button.disabled = mode == "RUN" and action not in ["RETURN", "SPEED_1", "SPEED_2", "SPEED_4"]

func _start_run() -> void:
	mode = "RUN"
	tool = ""
	energy = 0
	entered = 0
	killed = 0
	energy_earned = 0
	rooms_visited = 0
	trap_hits = 0
	for room in dungeon.rooms.values(): room.defeated = false
	_spawn_hero()
	event_text = "던전 영업 시작! 새로운 용사가 입장했습니다."
	_update_buttons()

func _spawn_hero() -> void:
	var entrance := dungeon.entrance_id()
	hero = DungeonHero.new(entrance)
	entered += 1
	hero.enter(entrance, dungeon.rooms[entrance].connections)
	hero.state = "EXPLORING"
	hero_timer = 0.7 / speed

func _process(delta: float) -> void:
	if mode == "RUN" and hero != null:
		_process_hero(delta * speed)
	queue_redraw()

func _process_hero(delta: float) -> void:
	if result_text != "": return
	if combat_timer > 0:
		combat_timer -= delta
		if combat_timer <= 0: _combat_round()
		return
	hero_timer -= delta
	if hero_timer > 0: return
	var room: DungeonRoom = dungeon.rooms[hero.current_room]
	if hero.state == "MOVING" or hero.state == "BACKTRACKING":
		hero.enter(room.id, room.connections)
		hero.state = "EXPLORING"
		rooms_visited += 1
		_process_room(room)
		return
	var next_id := hero.choose_next()
	if next_id < 0:
		event_text = "갈 곳이 없어 입구로 돌아갑니다."
		_hero_died()
		return
	hero.move_to(next_id)
	var destination: DungeonRoom = dungeon.rooms[next_id]
	event_text = "용사가 %s(으)로 이동합니다." % GameData.room_name(destination.room_type)
	hero_timer = 0.65 / speed

func _process_room(room: DungeonRoom) -> void:
	match room.room_type:
		"Spike":
			hero.hp -= GameData.SPIKE_DAMAGE
			trap_hits += 1
			event_text = "가시 함정 발동! 체력 -%d" % GameData.SPIKE_DAMAGE
			if hero.hp <= 0: _hero_died()
		"Slime", "Boss":
			if room.defeated:
				event_text = "%s은(는) 이미 쓰러져 있습니다." % GameData.room_name(room.room_type)
			else:
				hero.state = "FIGHTING " + room.room_type.to_upper()
				event_text = "%s과(와) 전투 시작!" % GameData.room_name(room.room_type)
				combat_timer = 0.35 / speed
		"Treasure":
			hero.state = "FOUND TREASURE"
			event_text = "보물을 획득했습니다!"
			_finish_run()

func _combat_round() -> void:
	if hero == null or result_text != "": return
	var room: DungeonRoom = dungeon.rooms[hero.current_room]
	var monster_hp := GameData.SLIME_HP if room.room_type == "Slime" else GameData.BOSS_HP
	var monster_attack := GameData.SLIME_ATTACK if room.room_type == "Slime" else GameData.BOSS_ATTACK
	# Store remaining HP on the room for the duration of this run.
	if room.combat_hp < 0: room.combat_hp = monster_hp
	var remaining: int = room.combat_hp
	remaining -= GameData.HERO_ATTACK
	event_text = "용사가 %s을(를) 공격! 피해 %d" % [GameData.room_name(room.room_type), GameData.HERO_ATTACK]
	if remaining <= 0:
		room.defeated = true
		room.combat_hp = 0
		hero.state = "EXPLORING"
		event_text = "%s을(를) 쓰러뜨렸습니다!" % GameData.room_name(room.room_type)
		return
	room.combat_hp = remaining
	hero.hp -= monster_attack
	event_text = "%s의 공격! 용사 체력 -%d" % [GameData.room_name(room.room_type), monster_attack]
	if hero.hp <= 0:
		_hero_died()
	else:
		combat_timer = 0.35 / speed

func _hero_died() -> void:
	if hero == null: return
	hero.state = "DEAD"
	killed += 1
	energy += GameData.DEATH_ENERGY
	energy_earned += GameData.DEATH_ENERGY
	event_text = "용사 사망  •  에너지 +%d" % GameData.DEATH_ENERGY
	hero_timer = 1.0 / speed
	await get_tree().create_timer(1.0 / speed).timeout
	if mode == "RUN" and result_text == "": _spawn_hero()

func _finish_run() -> void:
	result_text = "던전 공략 완료\n\n입장한 용사: %d명\n사망한 용사: %d명\n\n획득 에너지: %d\n방문한 방: %d회\n함정 발동: %d회" % [entered, killed, energy_earned, rooms_visited, trap_hits]
	_update_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT: return
	if not event.pressed or not CANVAS_RECT.has_point(event.position): return
	var clicked := _room_at(event.position)
	if mode == "RUN": return
	if tool == "CONNECT" or tool == "DISCONNECT":
		if clicked < 0: return
		if connect_first < 0:
			connect_first = clicked
			event_text = "두 번째 방을 클릭하세요."
		else:
			if tool == "CONNECT":
				if dungeon.connect_rooms(connect_first, clicked): event_text = "방을 연결했습니다."
				else: event_text = "두 방을 연결할 수 없습니다."
			else:
				dungeon.disconnect_rooms(connect_first, clicked)
				event_text = "방 사이의 연결을 삭제했습니다."
			connect_first = -1
			queue_redraw()
		return
	if tool.begins_with("EMPTY") or tool in ["SPIKE", "SLIME", "BOSS", "TREASURE"]:
		var room := dungeon.add_room(tool.capitalize(), event.position)
		selected_room = room.id
		event_text = "%s을(를) 배치했습니다." % GameData.room_name(room.room_type)
		tool = ""
		queue_redraw()
		return
	if clicked >= 0:
		selected_room = clicked
		queue_redraw()

func _room_at(point: Vector2) -> int:
	for id in dungeon.rooms:
		if dungeon.rooms[id].position.distance_to(point) <= ROOM_RADIUS:
			return id
	return -1

func _draw() -> void:
	draw_rect(CANVAS_RECT, Color("#0c1324"), true)
	draw_rect(CANVAS_RECT, Color("#263a5b"), false, 2.0)
	for room in dungeon.rooms.values():
		for other_id in room.connections:
			if dungeon.rooms.has(other_id) and room.id < other_id:
				draw_line(room.position, dungeon.rooms[other_id].position, Color("#536b8d"), 3.0)
	for room in dungeon.rooms.values():
		var color := GameData.room_color(room.room_type)
		if mode == "RUN" and hero != null and not hero.visited_rooms.has(room.id): color = color.darkened(0.55)
		if room.id == selected_room: draw_circle(room.position, ROOM_RADIUS + 5, Color("#ffffff80"))
		draw_circle(room.position, ROOM_RADIUS, color)
		draw_arc(room.position, ROOM_RADIUS, 0, TAU, 32, Color("#ffffff"), 2.0)
		_draw_centered(room.label(), room.position - Vector2(0, 9), 12, Color("#101827"))
	if mode == "RUN" and hero != null and result_text == "":
		var hero_pos: Vector2 = dungeon.rooms[hero.current_room].position
		draw_circle(hero_pos, 13, Color("#ffffff"))
		draw_circle(hero_pos, 8, Color("#ff9f1c"))
	_draw_hud()

func _draw_hud() -> void:
	var mode_text := "편집" if mode == "EDIT" else "영업"
	var hud := "상태: %s    에너지: %d    입장: %d명    사망: %d명" % [mode_text, energy, entered, killed]
	if mode == "RUN" and hero != null:
		hud += "    용사 체력: %d / %d    행동: %s" % [max(hero.hp, 0), GameData.HERO_HP, _hero_state_name(hero.state)]
	draw_string(ui_font, Vector2(205, 95), hud, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dbeafe"))
	draw_string(ui_font, Vector2(205, 650), event_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#ffd166"))
	if result_text != "":
		draw_rect(Rect2(425, 190, 500, 360), Color("#111a2f"), true)
		draw_rect(Rect2(425, 190, 500, 360), Color("#ffd166"), false, 3.0)
		var lines := result_text.split("\n")
		for i in range(lines.size()): draw_string(ui_font, Vector2(475, 245 + i * 30), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if i == 0 else 16, Color("#ffffff"))

func _draw_centered(text: String, pos: Vector2, size: int, color: Color) -> void:
	var lines := text.split("\n")
	for i in range(lines.size()):
		var width := ui_font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(ui_font, pos + Vector2(-width / 2, i * 14), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _hero_state_name(value: String) -> String:
	match value:
		"EXPLORING": return "탐험 중"
		"CHOOSING PATH": return "길 선택 중"
		"MOVING": return "이동 중"
		"BACKTRACKING": return "되돌아가는 중"
		"FIGHTING SLIME": return "슬라임과 전투 중"
		"FIGHTING BOSS": return "보스와 전투 중"
		"FOUND TREASURE": return "보물 발견"
		"DEAD": return "사망"
		_: return value
