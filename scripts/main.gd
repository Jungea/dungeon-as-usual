extends Node2D

const CANVAS_RECT := Rect2(180, 116, 1070, 565)
const MINIMAP_RECT := Rect2(1010, 18, 240, 82)
const RESIZE_HANDLE := 14.0
const GRID_SIZE := 32.0

var dungeon := DungeonManager.new()
var mode := "EDIT"
var tool := ""
var depth1_selected := "VIEW"
var depth2_selected := ""
var pending_content := ""
var selected_room := -1
var corridor_first: Dictionary = {}
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
var hero_stack_total := 0
var event_log: Array[Dictionary] = []
var element_stats: Dictionary = {}
var death_causes: Dictionary = {}
var last_damage_source := ""
var last_damage_amount := 0
var last_damage_effect := ""
var event_text := "DEPTH 메뉴에서 작업을 선택하세요."
var result_text := ""
var buttons: Array[Dictionary] = []
var ui_font: Font
var placing := false
var draw_start := Vector2.ZERO
var draw_current := Vector2.ZERO
var drag_mode := ""
var drag_offset := Vector2.ZERO
var camera_offset := Vector2(720, 390)
var camera_zoom := 1.0
var panning := false
var pan_last := Vector2.ZERO
var space_down := false
var hover_world := Vector2.ZERO
var hover_on_canvas := false
var item_panel: Panel
var item_panel_list: VBoxContainer
var depth1_menu: Panel
var depth2_menu: Panel
var menu_rows: Array[Dictionary] = []
var depth2_rows: Array[Dictionary] = []
var room_name_panel: Panel
var room_name_input: LineEdit

func _ready() -> void:
	dungeon.reset()
	ui_font = ThemeDB.fallback_font
	_build_ui()
	_update_cursor(Vector2.ZERO)
	queue_redraw()

func _build_ui() -> void:
	var title := Label.new()
	title.text = "오늘도 던전 영업합니다"
	title.position = Vector2(24, 18)
	title.add_theme_font_size_override("font_size", 28)
	add_child(title)
	var subtitle := Label.new()
	subtitle.text = "오늘도 정상 영업 중  •  Sprint 2"
	subtitle.position = Vector2(26, 54)
	subtitle.modulate = Color("#8da9c4")
	add_child(subtitle)
	_build_depth_menus()
	_create_button("던전 오픈", Vector2(18, 565), "OPEN")
	_create_button("던전 수정", Vector2(18, 603), "RETURN")
	_create_button("x1", Vector2(18, 525), "SPEED_1")
	_create_button("x2", Vector2(72, 525), "SPEED_2")
	_create_button("x4", Vector2(126, 525), "SPEED_4")
	_build_item_panel()
	_build_room_name_panel()
	_refresh_depth_menus()

func _build_depth_menus() -> void:
	depth1_menu = Panel.new()
	depth1_menu.position = Vector2(18, 105)
	depth1_menu.size = Vector2(145, 170)
	add_child(depth1_menu)
	_create_menu_row(depth1_menu, "방", "ROOM", 0)
	_create_menu_row(depth1_menu, "장애물", "OBSTACLE", 34)
	_create_menu_row(depth1_menu, "몬스터", "MONSTER", 68)
	_create_menu_row(depth1_menu, "통로", "CORRIDOR", 102)
	_create_menu_row(depth1_menu, "보기", "VIEW", 136)

	depth2_menu = Panel.new()
	depth2_menu.position = Vector2(1005, 105)
	depth2_menu.size = Vector2(225, 255)
	depth2_menu.visible = false
	add_child(depth2_menu)

func _create_menu_row(parent: Control, label_text: String, action: String, y: float, register_depth1 := true) -> void:
	var row := Panel.new()
	row.position = Vector2(5, y + 5)
	row.size = Vector2(parent.size.x - 10, 28)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var label := Label.new()
	label.text = label_text
	label.position = Vector2(12, 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_menu_action(action))
	parent.add_child(row)
	if register_depth1: menu_rows.append({"row": row, "action": action})
	else: depth2_rows.append({"row": row, "action": action})

func _rebuild_depth2_menu(items: Array[Dictionary], title_text: String) -> void:
	for child in depth2_menu.get_children(): child.queue_free()
	depth2_rows.clear()
	var title := Label.new()
	title.text = title_text
	title.position = Vector2(12, 8)
	title.add_theme_font_size_override("font_size", 17)
	depth2_menu.add_child(title)
	for index in range(items.size()):
		var item: Dictionary = items[index]
		_create_menu_row(depth2_menu, item["label"], item["action"], 30 + index * 34, false)
	depth2_menu.size.y = 42 + items.size() * 34
	depth2_menu.visible = true

func _menu_action(action: String) -> void:
	if action == "VIEW":
		depth1_selected = "VIEW"
		depth2_selected = ""
		pending_content = ""
		tool = ""
		corridor_first = {}
		_hide_item_panel()
		depth2_menu.visible = false
		_refresh_depth_menus()
		event_text = "보기 상태입니다."
		_update_cursor(Vector2.ZERO)
		queue_redraw()
		return
	if action in ["ROOM", "OBSTACLE", "MONSTER", "CORRIDOR"]:
		depth1_selected = action
		depth2_selected = ""
		pending_content = ""
		corridor_first = {}
		if action == "ROOM":
			tool = "EMPTY"
			depth2_selected = "ROOM_SINGLE"
			event_text = "방 기본 단일 그리기: 맵을 클릭하세요."
			_rebuild_depth2_menu([
				{"label": "기본 단일 그리기", "action": "ROOM_SINGLE"},
				{"label": "그리기 모드", "action": "ROOM_MODE"},
				{"label": "입구방 설정", "action": "SET_ENTRANCE"},
				{"label": "보물방 설정", "action": "SET_TREASURE"},
				{"label": "삭제", "action": "DELETE_SINGLE"},
				{"label": "삭제 모드", "action": "DELETE_MODE"}
			], "방 메뉴")
		elif action == "OBSTACLE":
			tool = ""
			_rebuild_depth2_menu([
				{"label": "가시", "action": "CONTENT_SPIKE"},
				{"label": "독물", "action": "CONTENT_POISON"},
				{"label": "불구덩이", "action": "CONTENT_FIRE"}
			], "장애물 목록")
		elif action == "MONSTER":
			tool = ""
			_rebuild_depth2_menu([
				{"label": "약한 몬스터", "action": "CONTENT_WEAKMONSTER"},
				{"label": "중간 몬스터", "action": "CONTENT_MIDMONSTER"},
				{"label": "강한 몬스터", "action": "CONTENT_STRONGMONSTER"}
			], "몬스터 목록")
		else:
			tool = "DOOR"
			depth2_selected = "DOOR_SINGLE"
			_rebuild_depth2_menu([
				{"label": "그리기", "action": "DOOR_SINGLE"},
				{"label": "그리기 모드", "action": "DOOR_MODE"},
				{"label": "삭제", "action": "DISCONNECT_SINGLE"},
				{"label": "삭제 모드", "action": "DISCONNECT_MODE"}
			], "통로 메뉴")
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		queue_redraw()
		return
	_button_action(action)

func _refresh_depth_menus() -> void:
	for item in menu_rows:
		var row: Panel = item["row"]
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#263a5b") if item["action"] == depth1_selected else Color("#151d2d")
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		row.add_theme_stylebox_override("panel", style)
	if depth2_menu != null:
		for item in depth2_rows:
			var row: Panel = item["row"]
			var selected: bool = item["action"] == depth2_selected
			var style2 := StyleBoxFlat.new()
			style2.bg_color = Color("#36567c") if selected else Color("#151d2d")
			row.add_theme_stylebox_override("panel", style2)

func _build_item_panel() -> void:
	item_panel = Panel.new()
	item_panel.position = Vector2(1005, 105)
	item_panel.size = Vector2(225, 255)
	item_panel.visible = false
	add_child(item_panel)
	item_panel_list = VBoxContainer.new()
	item_panel_list.position = Vector2(12, 12)
	item_panel_list.size = Vector2(201, 230)
	item_panel.add_child(item_panel_list)

func _build_room_name_panel() -> void:
	room_name_panel = Panel.new()
	room_name_panel.position = Vector2(1005, 370)
	room_name_panel.size = Vector2(225, 86)
	room_name_panel.visible = false
	add_child(room_name_panel)
	var label := Label.new()
	label.text = "방 이름"
	label.position = Vector2(10, 8)
	room_name_panel.add_child(label)
	room_name_input = LineEdit.new()
	room_name_input.position = Vector2(10, 32)
	room_name_input.size = Vector2(130, 30)
	room_name_input.placeholder_text = "선택 사항"
	room_name_panel.add_child(room_name_input)
	var apply := Button.new()
	apply.text = "저장"
	apply.position = Vector2(145, 32)
	apply.size = Vector2(65, 30)
	apply.pressed.connect(_apply_room_name)
	room_name_panel.add_child(apply)

func _apply_room_name() -> void:
	if selected_room < 0 or not dungeon.rooms.has(selected_room): return
	var room: DungeonRoom = dungeon.rooms[selected_room]
	room.custom_name = room_name_input.text.strip_edges()
	event_text = "방 이름을 변경했습니다."
	queue_redraw()

func _update_room_name_panel() -> void:
	if room_name_panel == null: return
	var visible := mode == "EDIT" and selected_room >= 0 and dungeon.rooms.has(selected_room)
	room_name_panel.visible = visible
	if visible:
		var room: DungeonRoom = dungeon.rooms[selected_room]
		if not room_name_input.has_focus(): room_name_input.text = room.custom_name

func _show_item_panel(title_text: String, items: Array[Dictionary]) -> void:
	for child in item_panel_list.get_children(): child.queue_free()
	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 18)
	item_panel_list.add_child(title)
	for item in items:
		var button := Button.new()
		button.text = item["label"]
		button.custom_minimum_size = Vector2(195, 32)
		var action: String = item["action"]
		button.pressed.connect(func(): _button_action(action))
		item_panel_list.add_child(button)
	item_panel.visible = true

func _hide_item_panel() -> void:
	if item_panel != null: item_panel.visible = false

func _create_button(text: String, pos: Vector2, action: String) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = Vector2(145 if text.length() > 2 else 48, 30)
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
		pending_content = ""
		result_text = ""
		event_text = "던전을 수정할 수 있습니다."
		_update_buttons()
		_update_cursor(Vector2.ZERO)
		_hide_item_panel()
		queue_redraw()
		return
	if action == "SET_ENTRANCE" or action == "SET_TREASURE":
		depth2_selected = action
		tool = action
		event_text = "입구방으로 지정할 방을 클릭하세요." if action == "SET_ENTRANCE" else "보물방으로 지정할 방을 클릭하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action == "SHOW_OBSTACLES":
		_show_item_panel("장애물 목록", [
			{"label": "가시", "action": "CONTENT_SPIKE"},
			{"label": "독물", "action": "CONTENT_POISON"},
			{"label": "불구덩이", "action": "CONTENT_FIRE"}
		])
		return
	if action == "SHOW_MONSTERS":
		_show_item_panel("몬스터 목록", [
			{"label": "약한 몬스터", "action": "CONTENT_WEAKMONSTER"},
			{"label": "중간 몬스터", "action": "CONTENT_MIDMONSTER"},
			{"label": "강한 몬스터", "action": "CONTENT_STRONGMONSTER"}
		])
		return
	if mode == "RUN": return
	if action == "OPEN":
		var error := dungeon.validation_message()
		if error != "": event_text = error
		else: _start_run()
		_hide_item_panel()
		queue_redraw()
		return
	if action == "ROOM_SINGLE":
		depth2_selected = action
		tool = "EMPTY"
		event_text = "방 하나를 배치하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action == "ROOM_MODE":
		depth2_selected = action
		tool = "EMPTY_MODE"
		event_text = "방을 연속으로 배치하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action == "DELETE_SINGLE" or action == "DELETE_MODE":
		depth2_selected = action
		tool = "DELETE_SINGLE" if action == "DELETE_SINGLE" else "DELETE_MODE"
		event_text = "삭제할 방을 클릭하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action == "DELETE_LINK" or action == "DISCONNECT_SINGLE":
		depth2_selected = "DISCONNECT_SINGLE"
		tool = "DISCONNECT"
		corridor_first = {}
		event_text = "문을 삭제할 벽면을 클릭하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action == "DOOR" or action == "DOOR_SINGLE" or action == "DOOR_MODE":
		depth2_selected = action
		tool = "DOOR_MODE" if action == "DOOR_MODE" else "DOOR"
		corridor_first = {}
		event_text = "문을 만들 방의 벽면을 클릭하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action == "DISCONNECT_MODE":
		depth2_selected = action
		tool = "DISCONNECT_MODE"
		corridor_first = {}
		event_text = "삭제할 통로를 클릭하세요."
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	if action.begins_with("CONTENT"):
		depth2_selected = action
		pending_content = _content_from_action(action)
		tool = "CONTENT"
		event_text = "%s을(를) 배치할 방을 클릭하세요." % DungeonRoom.new(0, "Normal", Vector2.ZERO, Vector2.ONE).content_name()
		if pending_content != "":
			var names := {"Spike": "가시", "Poison": "독물", "Fire": "불구덩이", "WeakMonster": "약한 몬스터", "MidMonster": "중간 몬스터", "StrongMonster": "강한 몬스터"}
			event_text = "%s을(를) 배치할 방을 클릭하세요." % names.get(pending_content, "내용물")
		_refresh_depth_menus()
		_update_cursor(Vector2.ZERO)
		return
	tool = "EMPTY"
	event_text = "방을 드래그해서 그리세요."
	_update_cursor(Vector2.ZERO)

func _update_buttons() -> void:
	if mode == "RUN":
		_hide_item_panel()
		if depth2_menu != null: depth2_menu.visible = false
	for item in buttons:
		var button: Button = item["button"]
		var action: String = item["action"]
		button.disabled = mode == "RUN" and action not in ["RETURN", "SPEED_1", "SPEED_2", "SPEED_4"]

func _start_run() -> void:
	mode = "RUN"
	tool = ""
	event_log.clear()
	element_stats.clear()
	death_causes.clear()
	last_damage_source = ""
	last_damage_amount = 0
	last_damage_effect = ""
	energy = 0
	entered = 0
	killed = 0
	energy_earned = 0
	rooms_visited = 0
	trap_hits = 0
	for room in dungeon.rooms.values():
		room.defeated = false
		room.combat_hp = -1
	_spawn_hero()
	event_text = "던전 영업 시작! 입구방에서 용사가 출발합니다."
	_log_event("던전 오픈")
	_update_buttons()

func _spawn_hero() -> void:
	var entrance := -1
	for room in dungeon.rooms.values():
		if room.role == "Entrance":
			entrance = room.id
			break
	if entrance < 0: return
	hero = DungeonHero.new(entrance)
	entered += 1
	hero_stack_total += 1
	last_damage_source = ""
	last_damage_amount = 0
	last_damage_effect = ""
	hero.enter(entrance, dungeon.rooms[entrance].connections)
	hero.state = "EXPLORING"
	hero_timer = 1.1 / speed
	_log_event("용사 #%d 입장: 방 #%d %s" % [entered, entrance, dungeon.rooms[entrance].display_name()], entrance)

func _log_event(message: String, room_id: int = -1) -> void:
	event_log.push_front({"message": message, "room_id": room_id})
	if event_log.size() > 80: event_log.pop_back()

func _record_damage(source: String, room: DungeonRoom, amount: int, effect: String) -> void:
	if amount <= 0: return
	last_damage_source = source
	last_damage_amount = amount
	last_damage_effect = effect
	if not element_stats.has(source):
		element_stats[source] = {"damage": 0, "hits": 0, "kills": 0, "max": 0}
	var stats: Dictionary = element_stats[source]
	stats["damage"] += amount
	stats["hits"] += 1
	stats["max"] = max(int(stats["max"]), amount)
	element_stats[source] = stats
	_log_event("용사 #%d · 방 #%d · %s · 피해 %d · %s · HP %d/%d" % [entered, room.id, source, amount, effect, max(hero.hp, 0), GameData.HERO_HP], room.id)

func _process(delta: float) -> void:
	if mode == "RUN" and hero != null: _process_hero(delta * speed)
	_update_room_name_panel()
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
		if hero.state == "BACKTRACKING": event_text = "미탐험 갈림길로 복귀 중"
		hero.state = "EXPLORING"
		rooms_visited += 1
		_process_room(room)
		return
	var next_id := hero.choose_next()
	if next_id < 0:
		event_text = "더 이상 탐험할 길이 없습니다."
		_hero_died()
		return
	var was_backtracking := hero.state == "BACKTRACKING"
	hero.move_to(next_id)
	if was_backtracking: hero.state = "BACKTRACKING"
	var destination: DungeonRoom = dungeon.rooms[next_id]
	event_text = "용사가 %s(으)로 이동합니다." % destination.display_name()
	_log_event("용사 #%d 이동: 방 #%d %s" % [entered, destination.id, destination.display_name()], destination.id)
	hero_timer = (0.8 if was_backtracking else 1.1) / speed

func _process_room(room: DungeonRoom) -> void:
	if room.role == "Treasure":
		hero.state = "FOUND TREASURE"
		event_text = "보물을 획득했습니다!"
		_log_event("용사 #%d · 방 #%d · 보물 획득" % [entered, room.id], room.id)
		_finish_run()
		return
	_log_event("용사 #%d · 방 #%d 진입" % [entered, room.id], room.id)
	match room.content:
		"Spike":
			hero.hp -= GameData.SPIKE_DAMAGE
			trap_hits += 1
			_record_damage("가시", room, GameData.SPIKE_DAMAGE, "함정 발동")
			event_text = "가시 함정 발동! 체력 -%d" % GameData.SPIKE_DAMAGE
			if hero.hp <= 0: _hero_died()
		"Poison":
			hero.hp -= GameData.POISON_DAMAGE
			trap_hits += 1
			_record_damage("독물", room, GameData.POISON_DAMAGE, "독 효과")
			event_text = "독물 함정 발동! 체력 -%d" % GameData.POISON_DAMAGE
			if hero.hp <= 0: _hero_died()
		"Fire":
			hero.hp -= GameData.FIRE_DAMAGE
			trap_hits += 1
			_record_damage("불구덩이", room, GameData.FIRE_DAMAGE, "화염 효과")
			event_text = "불구덩이 발동! 체력 -%d" % GameData.FIRE_DAMAGE
			if hero.hp <= 0: _hero_died()
		"Slime", "WeakMonster", "MidMonster", "StrongMonster":
			if room.defeated:
				event_text = "%s은(는) 이미 쓰러져 있습니다." % room.content_name()
			else:
				hero.state = "FIGHTING " + room.content.to_upper()
				event_text = "%s과(와) 전투 시작!" % room.content_name()
				_log_event("용사 #%d · 방 #%d · %s 전투 시작" % [entered, room.id, room.content_name()], room.id)
				combat_timer = 0.8 / speed

func _combat_round() -> void:
	if hero == null or result_text != "": return
	var room: DungeonRoom = dungeon.rooms[hero.current_room]
	var monster_hp := GameData.SLIME_HP
	var monster_attack := GameData.SLIME_ATTACK
	if room.content == "MidMonster":
		monster_hp = GameData.MID_MONSTER_HP
		monster_attack = GameData.MID_MONSTER_ATTACK
	elif room.content == "StrongMonster":
		monster_hp = GameData.STRONG_MONSTER_HP
		monster_attack = GameData.STRONG_MONSTER_ATTACK
	if room.combat_hp < 0: room.combat_hp = monster_hp
	var remaining: int = room.combat_hp - GameData.HERO_ATTACK
	if remaining <= 0:
		room.defeated = true
		room.combat_hp = 0
		hero.state = "EXPLORING"
		event_text = "%s을(를) 쓰러뜨렸습니다!" % room.content_name()
		return
	room.combat_hp = remaining
	event_text = "용사가 %s을(를) 공격했습니다. 피해 %d" % [room.content_name(), GameData.HERO_ATTACK]
	hero.hp -= monster_attack
	_record_damage(room.content_name(), room, monster_attack, "몬스터 공격")
	if hero.hp <= 0:
		event_text = "%s의 공격! 용사 사망" % room.content_name()
		_hero_died()
	else:
		event_text = "%s의 공격! 용사 체력 -%d" % [room.content_name(), monster_attack]
		combat_timer = 0.8 / speed

func _hero_died() -> void:
	if hero == null: return
	hero.state = "DEAD"
	killed += 1
	var cause := last_damage_source if last_damage_source != "" else "원인 미상"
	death_causes[cause] = int(death_causes.get(cause, 0)) + 1
	if element_stats.has(cause):
		var cause_stats: Dictionary = element_stats[cause]
		cause_stats["kills"] += 1
		element_stats[cause] = cause_stats
	energy += GameData.DEATH_ENERGY
	energy_earned += GameData.DEATH_ENERGY
	event_text = "용사 사망  •  원인: %s  •  에너지 +%d" % [cause, GameData.DEATH_ENERGY]
	var death_room_id := hero.current_room
	_log_event("용사 #%d 사망 · 원인 %s · 마지막 피해 %d" % [entered, cause, last_damage_amount], death_room_id)
	await get_tree().create_timer(1.0 / speed).timeout
	if mode == "RUN" and result_text == "": _spawn_hero()

func _finish_run() -> void:
	var top_source := "없음"
	var top_damage := 0
	var top_kills := 0
	for source in element_stats:
		var stats: Dictionary = element_stats[source]
		if int(stats["damage"]) > top_damage:
			top_damage = int(stats["damage"])
			top_source = source
		if int(stats["kills"]) > top_kills: top_kills = int(stats["kills"])
	var causes := "없음"
	if not death_causes.is_empty():
		var cause_parts: Array[String] = []
		for cause in death_causes: cause_parts.append("%s %d명" % [cause, death_causes[cause]])
		causes = ", ".join(cause_parts)
	result_text = "던전 공략 완료\n\n입장한 용사: %d명\n사망한 용사: %d명\n사망 원인: %s\n\n최다 피해 요소: %s (%d)\n마지막 일격 횟수: %d\n\n획득 에너지: %d\n방문한 방: %d회\n함정 발동: %d회" % [entered, killed, causes, top_source, top_damage, top_kills, energy_earned, rooms_visited, trap_hits]
	_update_buttons()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_SPACE:
		space_down = event.pressed
		return
	if event is InputEventMouseMotion:
		hover_on_canvas = CANVAS_RECT.has_point(event.position)
		if hover_on_canvas: hover_world = _snap_point(_screen_to_world(event.position))
		if panning:
			camera_offset += event.position - pan_last
			pan_last = event.position
			queue_redraw()
		else: _handle_motion(event.position)
		_update_cursor(event.position)
		return
	if not event is InputEventMouseButton: return
	if event.button_index == MOUSE_BUTTON_MIDDLE or (event.button_index == MOUSE_BUTTON_LEFT and space_down):
		if event.pressed:
			panning = true
			pan_last = event.position
		else: panning = false
		return
	if event.button_index == MOUSE_BUTTON_LEFT and MINIMAP_RECT.has_point(event.position):
		if event.pressed: _focus_from_minimap(event.position)
		return
	if event.button_index == MOUSE_BUTTON_LEFT and depth1_selected == "VIEW" and CANVAS_RECT.has_point(event.position):
		if event.pressed:
			var view_world := _screen_to_world(event.position)
			var view_room: DungeonRoom = dungeon.room_at(view_world)
			if view_room == null:
				panning = true
				pan_last = event.position
			else:
				panning = false
				_handle_mouse_down(event.position)
		else:
			if panning:
				panning = false
			else:
				_handle_mouse_up(event.position)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if CANVAS_RECT.has_point(event.position):
			var before := _screen_to_world(event.position)
			camera_zoom = clamp(camera_zoom * (1.1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.9), 0.45, 2.2)
			camera_offset = event.position - before * camera_zoom
			queue_redraw()
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not CANVAS_RECT.has_point(event.position): return
	if event.pressed: _handle_mouse_down(event.position)
	else: _handle_mouse_up(event.position)

func _handle_mouse_down(point: Vector2) -> void:
	if mode == "RUN":
		var run_room: DungeonRoom = dungeon.room_at(_screen_to_world(point))
		if run_room != null:
			selected_room = run_room.id
			event_text = "방 #%d %s 상태를 확인 중입니다." % [run_room.id, _room_display_label(run_room)]
			queue_redraw()
		return
	var world_point := _screen_to_world(point)
	if tool == "EMPTY" or tool == "EMPTY_MODE":
		var room_position := _snap_point(world_point)
		var room := dungeon.add_room("Normal", room_position, DungeonManager.MIN_ROOM_SIZE)
		if room == null:
			event_text = "방 마진이 겹치지 않는 빈 공간을 클릭하세요."
		else:
			selected_room = room.id
			event_text = "3×3칸 방을 만들었습니다. 오른쪽 아래 모서리로 크기를 조절하세요."
			if tool == "EMPTY":
				tool = ""
				depth2_selected = ""
				_update_cursor(point)
		_update_cursor(point)
		queue_redraw()
		return
	if tool == "SET_ENTRANCE" or tool == "SET_TREASURE" or tool == "CONTENT" or tool == "DELETE_SINGLE" or tool == "DELETE_MODE":
		var clicked_room: DungeonRoom = dungeon.room_at(world_point)
		if clicked_room == null:
			event_text = "방을 클릭하세요."
			return
		selected_room = clicked_room.id
		if tool == "SET_ENTRANCE":
			for room in dungeon.rooms.values():
				if room.role == "Entrance": room.role = "Normal"
			clicked_room.role = "Entrance"
			clicked_room.content = "None"
			event_text = "입구방으로 설정했습니다."
			tool = ""
			depth2_selected = ""
		elif tool == "SET_TREASURE":
			clicked_room.role = "Treasure"
			clicked_room.content = "Treasure"
			event_text = "보물방으로 설정했습니다."
			tool = ""
			depth2_selected = ""
		elif tool == "CONTENT":
			if clicked_room.role == "Entrance":
				event_text = "입구방에는 내부 요소를 넣을 수 없습니다."
			elif clicked_room.role == "Treasure":
				event_text = "보물방은 보물 전용 방입니다."
			else:
				clicked_room.content = pending_content
				event_text = "%s을(를) 배치했습니다." % clicked_room.content_name()
				tool = ""
				depth2_selected = ""
		elif tool == "DELETE_SINGLE" or tool == "DELETE_MODE":
			var removed_id := clicked_room.id
			dungeon.remove_room(removed_id)
			selected_room = -1
			event_text = "방을 삭제했습니다."
			if tool == "DELETE_SINGLE":
				tool = ""
				depth2_selected = ""
		_refresh_depth_menus()
		_update_cursor(point)
		queue_redraw()
		return
	if tool == "DOOR" or tool == "DOOR_MODE" or tool == "DISCONNECT" or tool == "DISCONNECT_MODE":
		var margin_target := _margin_target_at(point)
		if margin_target.is_empty():
			event_text = "방과 방 사이의 마진 칸을 클릭하세요."
			return
		if tool == "DISCONNECT" or tool == "DISCONNECT_MODE":
			var target: int = margin_target["id"]
			var side: String = margin_target["side"]
			if dungeon.rooms.has(target) and dungeon.rooms[target].connections_by_side.has(side):
				var other_id: int = dungeon.rooms[target].connections_by_side[side]
				dungeon.disconnect_rooms(target, other_id)
				event_text = "통로를 삭제했습니다."
			else:
				event_text = "해당 마진 칸에 통로가 없습니다."
			if tool == "DISCONNECT":
				tool = ""
				depth2_selected = ""
				_refresh_depth_menus()
			queue_redraw()
			return
		if corridor_first.is_empty():
			corridor_first = margin_target
			event_text = "맞은편 방의 마진 칸을 클릭하세요."
			queue_redraw()
			return
		var first_id: int = corridor_first["id"]
		var first_side: String = corridor_first["side"]
		var second_id: int = margin_target["id"]
		var second_side: String = margin_target["side"]
		if second_id == first_id:
			event_text = "첫 번째 방과 다른 방의 마진 칸을 선택하세요."
			corridor_first = {}
			queue_redraw()
			return
		if second_side != _opposite_side(first_side):
			event_text = "두 방의 마주 보는 면에 있는 마진 칸을 선택하세요."
			corridor_first = {}
			queue_redraw()
			return
		if dungeon.touching_room_on_side(first_id, first_side) != second_id:
			event_text = "두 마진 칸이 서로 맞닿은 방에 속하지 않습니다."
			corridor_first = {}
			queue_redraw()
			return
		var first_room: DungeonRoom = dungeon.rooms[first_id]
		if first_room.connections.has(second_id):
			event_text = "두 방 사이에는 이미 통로가 있습니다."
			corridor_first = {}
			queue_redraw()
			return
		var first_cell: int = corridor_first["cell"]
		var second_cell: int = margin_target["cell"]
		if dungeon.connect_rooms_on_sides(first_id, second_id, first_side, second_side, first_cell, second_cell):
			event_text = "두 마진 칸을 연결해 통로를 만들었습니다."
		else:
			event_text = "해당 방면에는 이미 통로가 있습니다."
		corridor_first = {}
		if tool == "DOOR":
			tool = ""
			depth2_selected = ""
			_refresh_depth_menus()
		queue_redraw()
		return
	if depth1_selected == "CORRIDOR":
		event_text = "통로 메뉴가 선택된 상태에서는 방을 이동할 수 없습니다. 보기로 전환하세요."
		return
	var clicked: DungeonRoom = dungeon.room_at(world_point)
	if clicked == null: return
	selected_room = clicked.id
	if depth1_selected == "VIEW" and not clicked.connections.is_empty():
		drag_mode = ""
		event_text = "통로가 연결된 방은 이동하거나 크기를 조절할 수 없습니다."
		_update_cursor(point)
		queue_redraw()
		return
	if _resize_handle_hit(clicked, point):
		drag_mode = "RESIZE"
	else:
		drag_mode = "MOVE"
		drag_offset = world_point - clicked.position
	event_text = "%s을(를) 선택했습니다. 드래그로 이동하거나 오른쪽 아래 모서리로 크기를 바꾸세요." % clicked.display_name()

func _handle_mouse_up(point: Vector2) -> void:
	if placing:
		placing = false
		var rect: Rect2 = _make_rect(draw_start, draw_current)
		var room := dungeon.add_room("Normal", rect.position, rect.size)
		if room == null: event_text = "방이 겹치지 않는 빈 공간에 그려주세요."
		else:
			selected_room = room.id
			event_text = "%s을(를) 만들었습니다." % room.display_name()
		tool = ""
		draw_start = Vector2.ZERO
		draw_current = Vector2.ZERO
		drag_mode = ""
		queue_redraw()
		return
	drag_mode = ""
	_update_cursor(point)

func _handle_motion(point: Vector2) -> void:
	if mode == "RUN": return
	if placing:
		draw_current = _snap_point(_screen_to_world(point))
		queue_redraw()
		return
	if selected_room < 0 or not dungeon.rooms.has(selected_room): return
	var room: DungeonRoom = dungeon.rooms[selected_room]
	var world_point := _screen_to_world(point)
	if drag_mode == "MOVE": dungeon.move_room(room.id, _snap_point(world_point - drag_offset))
	elif drag_mode == "RESIZE": dungeon.resize_room(room.id, _snap_size(world_point - room.position))
	if drag_mode != "": queue_redraw()

func _snap_point(point: Vector2) -> Vector2:
	return Vector2(round(point.x / GRID_SIZE) * GRID_SIZE, round(point.y / GRID_SIZE) * GRID_SIZE)

func _snap_size(size: Vector2) -> Vector2:
	return Vector2(round(size.x / GRID_SIZE) * GRID_SIZE, round(size.y / GRID_SIZE) * GRID_SIZE).max(DungeonManager.MIN_ROOM_SIZE)

func _update_cursor(point: Vector2) -> void:
	if mode == "RUN":
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	if tool == "EMPTY" or tool == "EMPTY_MODE" or tool == "DOOR" or tool == "DOOR_MODE":
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		return
	if tool == "CONTENT":
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		return
	if tool == "SET_ENTRANCE" or tool == "SET_TREASURE" or tool == "DELETE_SINGLE" or tool == "DELETE_MODE" or tool == "DISCONNECT" or tool == "DISCONNECT_MODE":
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		return
	if selected_room >= 0 and dungeon.rooms.has(selected_room):
		var room: DungeonRoom = dungeon.rooms[selected_room]
		if depth1_selected == "VIEW" and not room.connections.is_empty():
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			return
		if _resize_handle_hit(room, point):
			Input.set_default_cursor_shape(Input.CURSOR_FDIAGSIZE)
			return
		if room.rect().has_point(_screen_to_world(point)):
			Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			return
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _make_rect(first: Vector2, second: Vector2) -> Rect2:
	var top_left := Vector2(min(first.x, second.x), min(first.y, second.y))
	var bottom_right := Vector2(max(first.x, second.x), max(first.y, second.y))
	var size := _snap_size(bottom_right - top_left)
	return Rect2(top_left, size)

func _resize_handle_hit(room: DungeonRoom, point: Vector2) -> bool:
	var handle := _world_to_screen(room.position + room.size)
	return point.distance_to(handle) <= RESIZE_HANDLE * 2.0

func _world_to_screen(point: Vector2) -> Vector2:
	return point * camera_zoom + camera_offset

func _screen_to_world(point: Vector2) -> Vector2:
	return (point - camera_offset) / camera_zoom

func _target_at(screen_point: Vector2) -> int:
	var world_point := _screen_to_world(screen_point)
	var room: DungeonRoom = dungeon.room_at(world_point)
	return -1 if room == null else room.id

func _margin_target_at(screen_point: Vector2) -> Dictionary:
	var world_point := _screen_to_world(screen_point)
	for room in dungeon.rooms.values():
		var rect: Rect2 = room.rect()
		var vertical_cells := int(rect.size.y / GRID_SIZE)
		var horizontal_cells := int(rect.size.x / GRID_SIZE)
		for cell in range(vertical_cells):
			if _margin_cell_rect(room, "LEFT", cell).has_point(world_point):
				return {"id": room.id, "side": "LEFT", "cell": cell}
			if _margin_cell_rect(room, "RIGHT", cell).has_point(world_point):
				return {"id": room.id, "side": "RIGHT", "cell": cell}
		for cell in range(horizontal_cells):
			if _margin_cell_rect(room, "TOP", cell).has_point(world_point):
				return {"id": room.id, "side": "TOP", "cell": cell}
			if _margin_cell_rect(room, "BOTTOM", cell).has_point(world_point):
				return {"id": room.id, "side": "BOTTOM", "cell": cell}
	return {}

func _draw() -> void:
	draw_rect(CANVAS_RECT, Color("#0c1324"), true)
	_draw_grid()
	draw_rect(CANVAS_RECT, Color("#263a5b"), false, 2.0)
	if placing:
		var preview := _make_rect(draw_start, draw_current)
		draw_rect(_world_rect_to_screen(preview), Color("#8da9c455"), true)
		draw_rect(_world_rect_to_screen(preview), Color("#ffffff"), false, 2.0)
	elif (tool == "EMPTY" or tool == "EMPTY_MODE") and hover_on_canvas:
		var preview_size := _snap_size(DungeonManager.MIN_ROOM_SIZE)
		var preview_rect: Rect2 = Rect2(hover_world, preview_size)
		var blocked := dungeon._overlaps_existing(preview_rect)
		var preview_color := Color("#ef476655") if blocked else Color("#8da9c455")
		var border_color := Color("#ef4766") if blocked else Color("#8da9c4")
		var preview_margin_rect: Rect2 = _world_rect_to_screen(preview_rect.grow(DungeonManager.ROOM_MARGIN))
		draw_rect(preview_margin_rect, Color("#61708a22"), true)
		draw_rect(preview_margin_rect, Color("#ef476688") if blocked else Color("#61708a80"), false, 1.0)
		draw_rect(_world_rect_to_screen(preview_rect), preview_color, true)
		draw_rect(_world_rect_to_screen(preview_rect), border_color, false, 2.0)
	for room in dungeon.rooms.values():
		for side in room.connections_by_side:
			var other_id: int = room.connections_by_side[side]
			if dungeon.rooms.has(other_id) and room.id < other_id:
				var other: DungeonRoom = dungeon.rooms[other_id]
				var other_side := _opposite_side(side)
				var room_cell: int = room.connection_cells_by_side.get(side, 0)
				var other_cell: int = other.connection_cells_by_side.get(other_side, 0)
				var corridor_start := _world_to_screen(dungeon.side_cell_point(room, side, room_cell))
				var corridor_end := _world_to_screen(dungeon.side_cell_point(other, other_side, other_cell))
				draw_line(corridor_start, corridor_end, Color("#a67c52"), 24.0 * camera_zoom)
				draw_line(corridor_start, corridor_end, Color("#e6c79a"), 3.0 * camera_zoom)
	for room in dungeon.rooms.values(): _draw_room(room)
	if not corridor_first.is_empty() and dungeon.rooms.has(corridor_first["id"]):
		var selected_margin_room: DungeonRoom = dungeon.rooms[corridor_first["id"]]
		var selected_margin_rect: Rect2 = _margin_cell_rect(selected_margin_room, str(corridor_first["side"]), int(corridor_first["cell"]))
		draw_rect(_world_rect_to_screen(selected_margin_rect), Color("#ffd16688"), true)
		draw_rect(_world_rect_to_screen(selected_margin_rect), Color("#ffd166"), false, 2.0)
	if mode == "RUN" and hero != null and result_text == "":
		var current_room: DungeonRoom = dungeon.rooms[hero.current_room]
		var hero_pos: Vector2 = _world_to_screen(current_room.position + current_room.size / 2.0)
		draw_circle(hero_pos, 16, Color("#ffffff"))
		draw_circle(hero_pos, 10, Color("#ff9f1c"))
		if hero.state.begins_with("FIGHTING"):
			var pulse := 22.0 + sin(Time.get_ticks_msec() / 90.0) * 4.0
			draw_arc(hero_pos, pulse, 0.0, TAU, 24, Color("#ef476f99"), 3.0)
			draw_string(ui_font, hero_pos + Vector2(-30, -28), "전투 중", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#ff8c8c"))
	_draw_hud()
	_draw_minimap()
	_draw_live_analysis()

func _draw_minimap() -> void:
	draw_rect(MINIMAP_RECT, Color("#0b1220cc"), true)
	draw_rect(MINIMAP_RECT, Color("#8da9c4aa"), false, 1.0)
	draw_string(ui_font, MINIMAP_RECT.position + Vector2(10, 18), "미니맵", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#dbeafe"))
	if dungeon.rooms.is_empty():
		draw_string(ui_font, MINIMAP_RECT.position + Vector2(10, 48), "방을 배치하세요", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8da9c4"))
		return
	var bounds := Rect2()
	var initialized := false
	for room in dungeon.rooms.values():
		if not initialized:
			bounds = room.rect()
			initialized = true
		else:
			bounds = bounds.merge(room.rect())
	bounds = bounds.grow(DungeonManager.ROOM_MARGIN)
	var inner := MINIMAP_RECT.grow(-8.0)
	inner.position.y += 8.0
	inner.size.y -= 8.0
	var scale_x: float = inner.size.x / max(bounds.size.x, 1.0)
	var scale_y: float = inner.size.y / max(bounds.size.y, 1.0)
	var map_scale: float = min(scale_x, scale_y)
	var offset := inner.position + (inner.size - bounds.size * map_scale) / 2.0
	for room in dungeon.rooms.values():
		for other_id in room.connections:
			if room.id < other_id and dungeon.rooms.has(other_id):
				var other: DungeonRoom = dungeon.rooms[other_id]
				draw_line(_minimap_point(room.position + room.size / 2.0, bounds, offset, map_scale), _minimap_point(other.position + other.size / 2.0, bounds, offset, map_scale), Color("#c9a66b99"), 2.0)
	for room in dungeon.rooms.values():
		var room_color := Color("#8da9c4")
		if room.role == "Entrance": room_color = Color("#4ecdc4")
		elif room.role == "Treasure": room_color = Color("#ffd166")
		var mini_rect := Rect2(_minimap_point(room.position, bounds, offset, map_scale), room.size * map_scale)
		draw_rect(mini_rect, room_color, true)
		draw_rect(mini_rect, Color("#ffffffcc"), false, 1.0)
		if mode == "RUN" and hero != null and room.id == hero.current_room:
			draw_rect(mini_rect.grow(2.0), Color("#ff9f1c"), false, 2.0)
	if mode == "RUN" and hero != null and dungeon.rooms.has(hero.current_room):
		var current: DungeonRoom = dungeon.rooms[hero.current_room]
		draw_circle(_minimap_point(current.position + current.size / 2.0, bounds, offset, map_scale), 3.5, Color("#ffffff"))

func _focus_from_minimap(screen_point: Vector2) -> void:
	if dungeon.rooms.is_empty(): return
	var bounds := Rect2()
	var initialized := false
	for room in dungeon.rooms.values():
		if not initialized:
			bounds = room.rect()
			initialized = true
		else:
			bounds = bounds.merge(room.rect())
	bounds = bounds.grow(DungeonManager.ROOM_MARGIN)
	var inner := MINIMAP_RECT.grow(-8.0)
	inner.position.y += 8.0
	inner.size.y -= 8.0
	var map_scale: float = min(inner.size.x / max(bounds.size.x, 1.0), inner.size.y / max(bounds.size.y, 1.0))
	var offset := inner.position + (inner.size - bounds.size * map_scale) / 2.0
	var world_point := bounds.position + (screen_point - offset) / map_scale
	camera_offset = CANVAS_RECT.get_center() - world_point * camera_zoom
	queue_redraw()

func _minimap_point(world_point: Vector2, bounds: Rect2, offset: Vector2, map_scale: float) -> Vector2:
	return offset + (world_point - bounds.position) * map_scale

func _draw_live_analysis() -> void:
	if mode != "RUN": return
	var panel := Rect2(925, 110, 325, 325)
	draw_rect(panel, Color("#0b1220dd"), true)
	draw_rect(panel, Color("#8da9c4aa"), false, 1.0)
	draw_string(ui_font, panel.position + Vector2(10, 20), "진행 분석", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dbeafe"))
	if hero != null:
		draw_string(ui_font, panel.position + Vector2(10, 43), "용사 #%d  HP %d/%d" % [entered, max(hero.hp, 0), GameData.HERO_HP], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffffff"))
		draw_string(ui_font, panel.position + Vector2(10, 62), "행동: %s" % _hero_state_name(hero.state), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8da9c4"))
	var log_y := 84
	if selected_room >= 0 and dungeon.rooms.has(selected_room):
		var inspected: DungeonRoom = dungeon.rooms[selected_room]
		var inspect_status := "탐험 대기"
		if hero != null and hero.current_room == inspected.id:
			inspect_status = "전투 중" if hero.state.begins_with("FIGHTING") else _hero_state_name(hero.state)
		if inspected.defeated: inspect_status = "전투 완료"
		draw_string(ui_font, panel.position + Vector2(10, 84), "선택 방 #%d %s · %s" % [inspected.id, inspected.custom_name, inspect_status], HORIZONTAL_ALIGNMENT_LEFT, 305, 11, Color("#ffd166"))
		if inspected.content_name() != "":
			draw_string(ui_font, panel.position + Vector2(10, 102), "요소: %s" % inspected.content_name(), HORIZONTAL_ALIGNMENT_LEFT, 305, 11, Color("#dbeafe"))
			log_y = 122
			if inspected.combat_hp >= 0:
				draw_string(ui_font, panel.position + Vector2(155, 102), "적 HP %d" % inspected.combat_hp, HORIZONTAL_ALIGNMENT_LEFT, 140, 11, Color("#ef8894"))
	draw_string(ui_font, panel.position + Vector2(10, log_y), "최근 이벤트", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#ffd166"))
	var visible_count: int = min(7, event_log.size())
	for index in range(visible_count):
		var entry: Dictionary = event_log[index]
		var message: String = entry["message"]
		var room_id: int = entry["room_id"]
		if room_id >= 0 and dungeon.rooms.has(room_id):
			var event_room: DungeonRoom = dungeon.rooms[room_id]
			if event_room.custom_name != "": message = message.replace("방 #%d" % room_id, "방 #%d %s" % [room_id, event_room.custom_name])
		draw_string(ui_font, panel.position + Vector2(10, log_y + 18 + index * 20), message, HORIZONTAL_ALIGNMENT_LEFT, 305, 10, Color("#dbeafe"))
	var total_damage := 0
	for source in element_stats: total_damage += int(element_stats[source]["damage"])
	draw_string(ui_font, panel.position + Vector2(10, 305), "누적 피해 %d  ·  사망 %d" % [total_damage, killed], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#73e6a5"))

func _draw_grid() -> void:
	var top_left := _screen_to_world(CANVAS_RECT.position)
	var bottom_right := _screen_to_world(CANVAS_RECT.end)
	var start_x: float = floor(top_left.x / GRID_SIZE) * GRID_SIZE
	var end_x: float = ceil(bottom_right.x / GRID_SIZE) * GRID_SIZE
	var start_y: float = floor(top_left.y / GRID_SIZE) * GRID_SIZE
	var end_y: float = ceil(bottom_right.y / GRID_SIZE) * GRID_SIZE
	var grid_color := Color("#24334d80")
	var line_width := 1.0
	var x := start_x
	while x <= end_x:
		var screen_x := _world_to_screen(Vector2(x, 0.0)).x
		if screen_x >= CANVAS_RECT.position.x and screen_x <= CANVAS_RECT.end.x:
			draw_line(Vector2(screen_x, CANVAS_RECT.position.y), Vector2(screen_x, CANVAS_RECT.end.y), grid_color, line_width)
		x += GRID_SIZE
	var y := start_y
	while y <= end_y:
		var screen_y := _world_to_screen(Vector2(0.0, y)).y
		if screen_y >= CANVAS_RECT.position.y and screen_y <= CANVAS_RECT.end.y:
			draw_line(Vector2(CANVAS_RECT.position.x, screen_y), Vector2(CANVAS_RECT.end.x, screen_y), grid_color, line_width)
		y += GRID_SIZE

func _margin_cell_rect(room: DungeonRoom, side: String, cell: int) -> Rect2:
	var rect: Rect2 = room.rect()
	match side:
		"LEFT": return Rect2(rect.position + Vector2(-GRID_SIZE, cell * GRID_SIZE), Vector2(GRID_SIZE, GRID_SIZE))
		"RIGHT": return Rect2(Vector2(rect.end.x, rect.position.y + cell * GRID_SIZE), Vector2(GRID_SIZE, GRID_SIZE))
		"TOP": return Rect2(rect.position + Vector2(cell * GRID_SIZE, -GRID_SIZE), Vector2(GRID_SIZE, GRID_SIZE))
		_: return Rect2(Vector2(rect.position.x + cell * GRID_SIZE, rect.end.y), Vector2(GRID_SIZE, GRID_SIZE))

func _opposite_side(side: String) -> String:
	match side:
		"RIGHT": return "LEFT"
		"LEFT": return "RIGHT"
		"BOTTOM": return "TOP"
		_: return "BOTTOM"

func _draw_room(room: DungeonRoom) -> void:
	var color := Color("#8da9c4")
	if room.role == "Entrance": color = Color("#4ecdc4")
	if room.role == "Treasure": color = Color("#ffd166")
	if room.content == "Spike": color = Color("#ef476f")
	if room.content == "Poison": color = Color("#9b5de5")
	if room.content == "Fire": color = Color("#f77f00")
	if room.content == "Slime": color = Color("#80ed99")
	if room.content == "MidMonster": color = Color("#7cc8ff")
	if room.content == "StrongMonster": color = Color("#c77dff")
	if room.content == "Treasure": color = Color("#ffd166")
	if mode == "RUN" and hero != null and not hero.visited_rooms.has(room.id): color = color.darkened(0.55)
	var rect: Rect2 = _world_rect_to_screen(room.rect())
	var margin_rect: Rect2 = _world_rect_to_screen(room.rect().grow(DungeonManager.ROOM_MARGIN))
	draw_rect(margin_rect, Color("#61708a22"), true)
	draw_rect(margin_rect, Color("#61708a80"), false, 1.0)
	if room.id == selected_room: draw_rect(rect.grow(5), Color("#ffffff80"), false, 3.0)
	draw_rect(rect, color, true)
	draw_rect(rect, Color("#ffffff"), false, 2.0)
	_draw_centered(_room_display_label(room), rect.position + rect.size / 2.0 + Vector2(0, 6), 16, Color("#101827"))
	if mode == "EDIT" and room.id == selected_room: draw_rect(Rect2(rect.end - Vector2(RESIZE_HANDLE, RESIZE_HANDLE), Vector2(RESIZE_HANDLE, RESIZE_HANDLE)), Color("#ffffff"), true)

func _world_rect_to_screen(rect: Rect2) -> Rect2:
	return Rect2(_world_to_screen(rect.position), rect.size * camera_zoom)

func _draw_hud() -> void:
	var mode_text := "편집" if mode == "EDIT" else "영업"
	var hud := "상태: %s    에너지: %d    입장: %d명    사망: %d명    용사 스택: %d" % [mode_text, energy, entered, killed, hero_stack_total]
	if mode == "RUN" and hero != null: hud += "    용사 체력: %d / %d    행동: %s" % [max(hero.hp, 0), GameData.HERO_HP, _hero_state_name(hero.state)]
	draw_string(ui_font, Vector2(205, 95), hud, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#dbeafe"))
	draw_string(ui_font, Vector2(205, 650), event_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffd166"))
	var entrance_count := 0
	var treasure_count := 0
	for room in dungeon.rooms.values():
		if room.role == "Entrance": entrance_count += 1
		if room.role == "Treasure": treasure_count += 1
	var entrance_color := Color("#73e6a5") if entrance_count == 1 else Color("#ef8894")
	var treasure_color := Color("#73e6a5") if treasure_count == 1 else Color("#ef8894")
	draw_string(ui_font, Vector2(18, 475), "보물방 %d/1" % treasure_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, treasure_color)
	draw_string(ui_font, Vector2(18, 498), "입구방 %d/1" % entrance_count, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, entrance_color)
	if result_text != "":
		draw_rect(Rect2(350, 125, 600, 500), Color("#111a2f"), true)
		draw_rect(Rect2(350, 125, 600, 500), Color("#ffd166"), false, 3.0)
		var lines := result_text.split("\n")
		for i in range(lines.size()): draw_string(ui_font, Vector2(400, 175 + i * 30), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if i == 0 else 16, Color("#ffffff"))

func _draw_centered(text: String, pos: Vector2, size: int, color: Color) -> void:
	var width := ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(ui_font, pos + Vector2(-width / 2, 0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _room_display_label(room: DungeonRoom) -> String:
	var base := room.custom_name if room.custom_name != "" else room.label()
	if mode == "RUN": return "%s #%d" % [base, room.id]
	return base

func _hero_state_name(value: String) -> String:
	match value:
		"EXPLORING": return "탐험 중"
		"CHOOSING PATH": return "길 선택 중"
		"MOVING": return "이동 중"
		"BACKTRACKING": return "미탐험 갈림길로 복귀 중"
		"FIGHTING SLIME": return "슬라임과 전투 중"
		"FIGHTING WEAKMONSTER": return "약한 몬스터와 전투 중"
		"FIGHTING MIDMONSTER": return "중간 몬스터와 전투 중"
		"FIGHTING STRONGMONSTER": return "강한 몬스터와 전투 중"
		"FOUND TREASURE": return "보물 발견"
		"DEAD": return "사망"
		_: return value

func _content_from_action(action: String) -> String:
	match action:
		"CONTENT_TREASURE": return "Treasure"
		"CONTENT_SPIKE": return "Spike"
		"CONTENT_POISON": return "Poison"
		"CONTENT_FIRE": return "Fire"
		"CONTENT_WEAKMONSTER": return "WeakMonster"
		"CONTENT_MIDMONSTER": return "MidMonster"
		"CONTENT_STRONGMONSTER": return "StrongMonster"
		"CONTENT_NONE": return "None"
		_: return ""
