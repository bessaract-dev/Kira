extends Node2D
## Строит уровень из файла data/levels/<id>.json.
## Каждый символ карты это клетка 32x32:
##   #  стена/пол          =  уступ (можно запрыгнуть снизу)
##   P  старт Киры         o  осколок памяти
##   ^  шипы               S  голубое пламя (сохранение и прокачка)
##   e  душа               k  скелет в броне
##   d  заводная кукла     H  кольцо для крюка
##   c  голубой факел      C  погоня (стена тьмы)
## Остальные буквы описаны в разделе "entities" самого JSON (записки, предметы, выходы).

const TILE := 32
const ATLAS := 0
const SOLID_TILES := {"crypt": Vector2i(0, 0), "catacombs": Vector2i(1, 0)}
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
	"soul": preload("res://scenes/entities/enemy_soul.tscn"),
	"skeleton": preload("res://scenes/entities/enemy_skeleton.tscn"),
	"doll": preload("res://scenes/entities/enemy_doll.tscn"),
	"hook": preload("res://scenes/entities/hook_point.tscn"),
	"chaser": preload("res://scenes/entities/chaser.tscn"),
}
## Символы, одинаковые для всех уровней.
const SYMBOLS := {
	"o": "shard", "^": "spikes", "S": "shrine", "c": "candle",
	"e": "soul", "k": "skeleton", "d": "doll", "H": "hook", "C": "chaser",
}
## Эти объекты ставятся в центр клетки, остальные стоят на её нижней грани.
const CENTERED := ["hook"]
## Эти объекты исчезают навсегда, когда их подобрали.
const PERSISTENT := ["note", "item", "shard", "trigger"]
const BACKGROUNDS := {
	"crypt": preload("res://scenes/backgrounds/crypt.tscn"),
	"catacombs": preload("res://scenes/backgrounds/catacombs.tscn"),
	"depths": preload("res://scenes/backgrounds/depths.tscn"),
}

## Если пусто, берётся GameState.current_level.
@export var level_id := ""

var player: Player
var _spawn := Vector2.ZERO
var _chaser: Node2D = null
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
	var solid: Vector2i = SOLID_TILES.get(theme.get("tile", "crypt"), SOLID_TILES["crypt"])
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
	node.position = pos - Vector2(0, TILE / 2.0) if type in CENTERED else pos
	if type == "chaser":
		_chaser = node
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
	if _chaser:
		# Тьма появляется позади Киры (и после возрождения тоже).
		_chaser.place(player.position.x - 360.0, _size.y * TILE)
		_chaser.stop_x = (_size.x - 12) * TILE
	player.died.connect(_on_player_died)
	_hud.bind_player(player)


func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	GameState.heal_full()
	# Перезагружаем уровень: враги вернутся, а подобранные вещи нет.
	SceneLoader.change_scene(GameState.LEVEL_SCENE)
