extends Node
## Глобальное состояние игры (автозагрузка GameState).
## Хранит всё, что переживает смену уровня: здоровье, осколки памяти,
## улучшения, способности цепей, буквы имени, записки и последнее голубое пламя.
## Все тексты и числа читаются из папки data/, чтобы их было легко менять.

signal shards_changed(amount: int)
signal health_changed(hp: int, max_hp: int)
signal item_added(item_id: String)
signal note_collected(note_id: String)
signal upgrade_bought(upgrade_id: String)
signal abilities_changed
signal message_requested(text: String)
signal touch_mode_changed(enabled: bool)

const LEVELS := {
	"level_01": "res://data/levels/level_01.json",
	"level_02": "res://data/levels/level_02.json",
	"level_03": "res://data/levels/level_03.json",
}
const LEVEL_SCENE := "res://scenes/levels/level.tscn"
const ENDING_SCENE := "res://scenes/ui/ending.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var base_stats: Dictionary = {}
var upgrades_db: Dictionary = {}
var notes_db: Dictionary = {}
var items_db: Dictionary = {}

var current_level := "level_01"
var shards := 0
var hp := 3
var inventory: Array[String] = []
var collected_notes: Array[String] = []
## Способности: whip, throw, hook, free (цепи разбиты), wall_jump
var abilities: Array[String] = []
## id улучшения -> купленный уровень
var upgrade_levels: Dictionary = {}
## Уже подобранные вещи на уровнях (чтобы не появлялись снова после смерти)
var picked: Dictionary = {}
## Позиция последнего голубого пламени на текущем уровне (Vector2) или null
var checkpoint = null
var touch_mode := false
## Кнопки мыши, снятые с действий в сенсорном режиме (действие -> события)
var _mouse_bindings: Dictionary = {}


func _ready() -> void:
	base_stats = load_json("res://data/player.json")
	upgrades_db = load_json("res://data/upgrades.json")
	notes_db = load_json("res://data/notes.json")
	items_db = load_json("res://data/items.json")
	for db in [base_stats, upgrades_db, items_db]:
		db.erase("_comment")
	touch_mode = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	_update_mouse_bindings()
	new_game()


func _unhandled_input(event: InputEvent) -> void:
	# F2 включает сенсорные кнопки на ПК, чтобы проверить их мышкой.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F2:
		set_touch_mode(not touch_mode)


static func load_json(path: String) -> Dictionary:
	var json := load(path) as JSON
	if json == null or not (json.data is Dictionary):
		push_error("Не удалось прочитать " + path)
		return {}
	return json.data


func new_game() -> void:
	current_level = "level_01"
	shards = 0
	inventory.clear()
	collected_notes.clear()
	abilities.clear()
	upgrade_levels.clear()
	picked.clear()
	checkpoint = null
	hp = get_max_hp()


# --- Характеристики и прокачка ---

func get_stat(stat: String) -> float:
	var value: float = base_stats.get(stat, 0.0)
	for id in upgrade_levels:
		var upgrade: Dictionary = upgrades_db.get(id, {})
		if upgrade.get("stat") == stat:
			value += float(upgrade.get("per_level", 0)) * upgrade_levels[id]
	return value


func get_max_hp() -> int:
	return int(get_stat("max_hp"))


func get_upgrade_level(id: String) -> int:
	return upgrade_levels.get(id, 0)


## Цена следующего уровня улучшения или -1, если уже максимум.
func get_upgrade_cost(id: String) -> int:
	var costs: Array = upgrades_db.get(id, {}).get("costs", [])
	var level := get_upgrade_level(id)
	return int(costs[level]) if level < costs.size() else -1


func buy_upgrade(id: String) -> bool:
	var cost := get_upgrade_cost(id)
	if cost < 0 or shards < cost:
		return false
	add_shards(-cost)
	upgrade_levels[id] = get_upgrade_level(id) + 1
	upgrade_bought.emit(id)
	if upgrades_db[id].get("stat") == "max_hp":
		heal_full()
	return true


func add_shards(amount: int) -> void:
	shards = max(0, shards + amount)
	shards_changed.emit(shards)


# --- Здоровье ---

func damage(amount: int) -> void:
	hp = max(0, hp - amount)
	health_changed.emit(hp, get_max_hp())


func heal_full() -> void:
	hp = get_max_hp()
	health_changed.emit(hp, get_max_hp())


# --- Способности цепей ---

func has_ability(id: String) -> bool:
	return abilities.has(id)


## Буквы имени, которые Кира уже вспомнила, по порядку подбора.
func get_letters() -> Array[String]:
	var letters: Array[String] = []
	for id in inventory:
		var glyph: String = get_item(id).get("glyph", "")
		if glyph != "":
			letters.append(glyph)
	return letters


# --- Предметы и записки ---

func add_item(id: String) -> void:
	if not inventory.has(id):
		inventory.append(id)
	var item := get_item(id)
	for ability in item.get("grants", []):
		if not abilities.has(ability):
			abilities.append(ability)
	for ability in item.get("removes", []):
		abilities.erase(ability)
	item_added.emit(id)
	if item.has("grants") or item.has("removes"):
		abilities_changed.emit()


func has_items(ids: Array) -> bool:
	for id in ids:
		if not inventory.has(id):
			return false
	return true


func get_item(id: String) -> Dictionary:
	return items_db.get(id, {"name": id, "description": ""})


func collect_note(id: String) -> void:
	if not collected_notes.has(id):
		collected_notes.append(id)
	note_collected.emit(id)


func get_note(id: String) -> Dictionary:
	return notes_db.get(id, {"title": "???", "text": ""})


func mark_picked(key: String) -> void:
	picked[key] = true


func is_picked(key: String) -> bool:
	return picked.has(key)


func show_message(text: String) -> void:
	message_requested.emit(text)


# --- Переходы ---

## target: id уровня ("level_02"), "ending" или "menu".
func go_to(target: String) -> void:
	match target:
		"ending":
			SceneLoader.change_scene(ENDING_SCENE)
		"menu":
			SceneLoader.change_scene(MENU_SCENE)
		_:
			current_level = target
			checkpoint = null
			SceneLoader.change_scene(LEVEL_SCENE)


func get_level_data() -> Dictionary:
	return load_json(LEVELS.get(current_level, LEVELS["level_01"]))


func set_touch_mode(enabled: bool) -> void:
	touch_mode = enabled
	_update_mouse_bindings()
	touch_mode_changed.emit(enabled)


## Касание экрана Godot превращает ещё и в щелчок мыши, а на щелчках висят
## хлыст и бросок. В сенсорном режиме снимаем кнопки мыши с действий,
## чтобы атака шла только от своих экранных кнопок.
func _update_mouse_bindings() -> void:
	if touch_mode:
		for action in InputMap.get_actions():
			if action.begins_with("ui_") or _mouse_bindings.has(action):
				continue
			var removed: Array = []
			for event in InputMap.action_get_events(action):
				if event is InputEventMouseButton:
					removed.append(event)
					InputMap.action_erase_event(action, event)
			if not removed.is_empty():
				_mouse_bindings[action] = removed
	else:
		for action in _mouse_bindings:
			for event in _mouse_bindings[action]:
				InputMap.action_add_event(action, event)
		_mouse_bindings.clear()
