extends Node2D
## Строит уровень из файла data/levels/<id>.json.
## Каждый символ карты это клетка 32x32:
##   #  стена/пол          =  полка (можно запрыгнуть снизу)
##   P  старт героини      o  осколок памяти
##   ^  шипы               S  свеча-святилище
##   E  враг-тень          c  свеча (просто свет)
## Остальные буквы описаны в разделе "entities" самого JSON (записки, предметы, выходы).

const TILE := 32
const ATLAS := 0
const SOLID_TILES := {"stone": Vector2i(0, 0), "wood": Vector2i(1, 0)}
const DEEP_TILE := Vector2i(3, 0)
const PLATFORM_TILE := Vector2i(2, 0)

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENTITY_SCENES := {
	"note": preload("res://scenes/entities/note.tscn"),
	"item": preload("res://scenes/entities/item.tscn"),
	"exit": preload("res://scenes/entities/exit.tscn"),
	"inspect": preload("res://scenes/entities/inspect.tscn"),
	"shrine": preload("res://scenes/entities/shrine.tscn"),
	"trigger": preload("res://scenes/entities/story_trigger.tscn"),
	"candle": preload("res://scenes/entities/candle.tscn"),
	"shard": preload("res://scenes/entities/memory_shard.tscn"),
	"spikes": preload("res://scenes/entities/spikes.tscn"),
	"enemy": preload("res://scenes/entities/enemy_shade.tscn"),
}
## Символы, одинаковые для всех уровней.
const SYMBOLS := {"o": "shard", "^": "spikes", "S": "shrine", "E": "enemy", "c": "candle"}
## Эти объекты исчезают навсегда, когда их подобрали.
const PERSISTENT := ["note", "item", "shard", "trigger"]
const BACKGROUNDS := {
	"house": preload("res://scenes/backgrounds/house.tscn"),
	"otherworld": preload("res://scenes/backgrounds/otherworld.tscn"),
}

## Если пусто, берётся GameState.current_level.
@export var level_id := ""

var player: Player
var _spawn := Vector2.ZERO
var _size := Vector2i.ZERO

@onready var _tiles: TileMapLayer = $Tiles
@onready var _entities: Node2D = $Entities
@onready var _darkness: CanvasModulate = $Darkness
@onready var _hud: CanvasLayer = $HUD


func _ready() -> void:
	if level_id != "":
		GameState.current_level = level_id
	if GameState.hp <= 0:
		GameState.heal_full()
	var data := GameState.get_level_data()
	_build(data)
	_spawn_player()


func _build(data: Dictionary) -> void:
	var theme: Dictionary = data.get("theme", {})
	var solid: Vector2i = SOLID_TILES.get(theme.get("tile", "stone"), SOLID_TILES["stone"])
	_darkness.color = Color(theme.get("darkness", "#ffffff"))
	var background: PackedScene = BACKGROUNDS.get(theme.get("background", ""))
	if background:
		var bg := background.instantiate()
		add_child(bg)
		move_child(bg, 0)

	var rows: Array = data.get("map", [])
	var legend: Dictionary = data.get("entities", {})
	for y in rows.size():
		var row: String = rows[y]
		_size.x = max(_size.x, row.length())
		for x in row.length():
			var symbol := row[x]
			var cell := Vector2i(x, y)
			var pos := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
			match symbol:
				".":
					pass
				"#":
					var deep: bool = y > 0 and x < rows[y - 1].length() and rows[y - 1][x] == "#"
					_tiles.set_cell(cell, ATLAS, DEEP_TILE if deep else solid)
				"=":
					_tiles.set_cell(cell, ATLAS, PLATFORM_TILE)
				"P":
					_spawn = pos
				_:
					if SYMBOLS.has(symbol):
						_spawn_entity({"type": SYMBOLS[symbol]}, pos, cell)
					elif legend.has(symbol):
						_spawn_entity(legend[symbol], pos, cell)
					else:
						push_warning("Неизвестный символ '%s' в клетке %s" % [symbol, cell])
	_size.y = rows.size()


func _spawn_entity(info: Dictionary, pos: Vector2, cell: Vector2i) -> void:
	var type: String = info.get("type", "")
	if not ENTITY_SCENES.has(type):
		push_warning("Неизвестный тип объекта: " + type)
		return
	var key := "%s:%d:%d" % [GameState.current_level, cell.x, cell.y]
	if type in PERSISTENT and GameState.is_picked(key):
		return
	var node: Node2D = ENTITY_SCENES[type].instantiate()
	node.position = pos
	if type in PERSISTENT:
		node.persist_key = key
	if node.has_method("configure"):
		node.configure(info)
	_entities.add_child(node)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = GameState.checkpoint if GameState.checkpoint != null else _spawn
	player.kill_y = _size.y * TILE + 200.0
	add_child(player)
	var camera: Camera2D = player.get_node("Camera2D")
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = _size.x * TILE
	camera.limit_bottom = _size.y * TILE
	camera.reset_smoothing()
	player.died.connect(_on_player_died)
	_hud.bind_player(player)


func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	GameState.heal_full()
	# Перезагружаем уровень: враги вернутся, а подобранные вещи нет.
	SceneLoader.change_scene(GameState.LEVEL_SCENE)
