extends Node
## Звуки и музыка (автозагрузка Sound).
## Sound.play("jump") проигрывает звук, указанный в data/sounds.json.
## Нет файла: тишина и никаких ошибок, поэтому звуки можно добавлять по одному.
## Музыка уровня берётся из поля "music" в JSON уровня.

const VOICES := 8

var _db: Dictionary = {}
var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_db = GameState.load_json("res://data/sounds.json")
	_db.erase("_comment")
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -10.0
	add_child(_music)


func play(event: String, pitch_jitter := 0.08) -> void:
	var stream := _get_stream(event)
	if stream == null:
		return
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = stream
	player.volume_db = _db[event].get("volume_db", 0.0)
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func play_music(path: String) -> void:
	if path == "" or not ResourceLoader.exists(path):
		_music.stop()
		return
	var stream: AudioStream = load(path)
	if _music.stream == stream and _music.playing:
		return
	if "loop" in stream:
		stream.loop = true
	_music.stream = stream
	_music.play()


func _get_stream(event: String) -> AudioStream:
	if _cache.has(event):
		return _cache[event]
	var path: String = _db.get(event, {}).get("file", "")
	var stream: AudioStream = load(path) if path != "" and ResourceLoader.exists(path) else null
	_cache[event] = stream
	return stream
