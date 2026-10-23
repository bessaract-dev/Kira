extends CanvasLayer
## Интерфейс на уровне: здоровье, осколки, буквы имени, подсказки, записки,
## окно прокачки у голубого пламени, меню паузы с сумкой и сенсорные кнопки.

enum Mode { PLAY, NOTE, UPGRADES, PAUSE }

const HEART_FULL := preload("res://assets/textures/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/textures/ui/heart_empty.png")

var _mode := Mode.PLAY
var _message_tween: Tween

@onready var _hearts: HBoxContainer = %Hearts
@onready var _shard_label: Label = %ShardLabel
@onready var _letters: Label = %Letters
@onready var _prompt_label: Label = %PromptLabel
@onready var _message_box: Control = %MessageBox
@onready var _message_label: Label = %MessageLabel
@onready var _touch_controls: Control = %TouchControls
@onready var _note_panel: Control = %NotePanel
@onready var _upgrade_panel: Control = %UpgradePanel
@onready var _upgrade_list: VBoxContainer = %UpgradeList
@onready var _pause_menu: Control = %PauseMenu
@onready var _items_list: ItemList = %ItemsList
@onready var _notes_list: ItemList = %NotesList
@onready var _detail_text: RichTextLabel = %DetailText


func _ready() -> void:
	add_to_group("hud")
	_message_box.modulate.a = 0.0
	GameState.health_changed.connect(_update_hearts)
	GameState.shards_changed.connect(_update_shards)
	GameState.note_collected.connect(_on_note_collected)
	GameState.message_requested.connect(show_message)
	GameState.item_added.connect(_update_letters.unbind(1))
	%NoteClose.pressed.connect(_set_mode.bind(Mode.PLAY))
	%UpgradeClose.pressed.connect(_set_mode.bind(Mode.PLAY))
	%ResumeButton.pressed.connect(_set_mode.bind(Mode.PLAY))
	%MenuButton.pressed.connect(GameState.go_to.bind("menu"))
	_items_list.item_selected.connect(_on_item_selected)
	_notes_list.item_selected.connect(_on_note_selected)
	_update_hearts(GameState.hp, GameState.get_max_hp())
	_update_shards(GameState.shards)
	_update_letters()
	_set_mode(Mode.PLAY)


func bind_player(player: Player) -> void:
	player.focus_changed.connect(_on_focus_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif _mode == Mode.NOTE and event.is_action_pressed("interact"):
		_set_mode(Mode.PLAY)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	# Кнопка «Назад» на Android
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_toggle_pause()


func _toggle_pause() -> void:
	_set_mode(Mode.PAUSE if _mode == Mode.PLAY else Mode.PLAY)


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_note_panel.visible = mode == Mode.NOTE
	_upgrade_panel.visible = mode == Mode.UPGRADES
	_pause_menu.visible = mode == Mode.PAUSE
	_prompt_label.visible = mode == Mode.PLAY
	_touch_controls.set_active(mode == Mode.PLAY)
	get_tree().paused = mode != Mode.PLAY
	match mode:
		Mode.NOTE:
			%NoteClose.grab_focus()
		Mode.UPGRADES:
			%UpgradeClose.grab_focus()
		Mode.PAUSE:
			_fill_pause_menu()
			%ResumeButton.grab_focus()


# --- Полоска сверху ---

func _update_hearts(hp: int, max_hp: int) -> void:
	for child in _hearts.get_children():
		child.queue_free()
	for i in max_hp:
		var heart := TextureRect.new()
		heart.texture = HEART_FULL if i < hp else HEART_EMPTY
		heart.custom_minimum_size = Vector2(30, 28)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_hearts.add_child(heart)


func _update_shards(amount: int) -> void:
	_shard_label.text = str(amount)


## Имя по буквам: «К И _ _». Скрыто, пока Кира не вспомнила ни одной.
func _update_letters() -> void:
	var letters := GameState.get_letters()
	var slots: Array[String] = []
	for i in 4:
		slots.append(letters[i] if i < letters.size() else "_")
	_letters.text = " ".join(slots)
	_letters.visible = not letters.is_empty() or GameState.current_level == "level_02"


func _on_focus_changed(target: Interactable) -> void:
	if target == null:
		_prompt_label.text = ""
	else:
		var key_hint := "" if GameState.touch_mode else "[E]  "
		_prompt_label.text = key_hint + target.get_prompt()


func show_message(text: String) -> void:
	_message_label.text = text
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_property(_message_box, "modulate:a", 1.0, 0.25)
	_message_tween.tween_interval(clampf(text.length() * 0.06, 2.5, 7.0))
	_message_tween.tween_property(_message_box, "modulate:a", 0.0, 0.6)


# --- Записки ---

func _on_note_collected(note_id: String) -> void:
	var note := GameState.get_note(note_id)
	%NoteTitle.text = note.get("title", "")
	%NoteText.text = note.get("text", "")
	_set_mode(Mode.NOTE)


# --- Прокачка у голубого пламени ---

func open_upgrades() -> void:
	_fill_upgrades()
	_set_mode(Mode.UPGRADES)


func _fill_upgrades() -> void:
	for child in _upgrade_list.get_children():
		child.queue_free()
	%UpgradeShards.text = "Осколков памяти: %d    Пламя восстановило силы." % GameState.shards
	for id in GameState.upgrades_db:
		var info: Dictionary = GameState.upgrades_db[id]
		var level := GameState.get_upgrade_level(id)
		var max_level: int = info.get("costs", []).size()
		var cost := GameState.get_upgrade_cost(id)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = "%s   %d/%d" % [info.get("name", id), level, max_level]
		var description := Label.new()
		description.text = info.get("description", "")
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 18)
		description.modulate = Color(0.8, 0.78, 0.75)
		texts.add_child(title)
		texts.add_child(description)

		var button := Button.new()
		button.custom_minimum_size = Vector2(200, 0)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.text = "Изучено" if cost < 0 else "Купить: %d" % cost
		button.disabled = cost < 0 or GameState.shards < cost
		button.pressed.connect(_on_buy_pressed.bind(id))
		row.add_child(texts)
		row.add_child(button)
		_upgrade_list.add_child(row)


func _on_buy_pressed(id: String) -> void:
	if GameState.buy_upgrade(id):
		Sound.play("upgrade")
		show_message("Новая сила: " + GameState.upgrades_db[id].get("name", id))
		_fill_upgrades()


# --- Пауза и сумка ---

func _fill_pause_menu() -> void:
	_items_list.clear()
	for id in GameState.inventory:
		var item := GameState.get_item(id)
		var icon: Texture2D = load(item["icon"]) if item.has("icon") else null
		_items_list.add_item(item.get("name", id), icon)
	_notes_list.clear()
	for id in GameState.collected_notes:
		_notes_list.add_item(GameState.get_note(id).get("title", id))
	_detail_text.text = "Выбери предмет или записку."


func _on_item_selected(index: int) -> void:
	_notes_list.deselect_all()
	var item := GameState.get_item(GameState.inventory[index])
	_detail_text.text = item.get("description", "")


func _on_note_selected(index: int) -> void:
	_items_list.deselect_all()
	var note := GameState.get_note(GameState.collected_notes[index])
	_detail_text.text = "[b]%s[/b]\n%s" % [note.get("title", ""), note.get("text", "")]
