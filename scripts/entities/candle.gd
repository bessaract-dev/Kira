extends Node2D
## Мерцающий источник света (свеча, факел). Цвет можно задать в JSON уровня: "color": "#ff3040".

@export var flicker_strength := 0.2
@export var flicker_speed := 6.0
@export var color := Color(0.45, 0.7, 1.0)

var _noise := FastNoiseLite.new()
var _time := randf() * 100.0
var _base_energy := 1.0

@onready var _light: PointLight2D = $Light


func configure(data: Dictionary) -> void:
	if data.has("color"):
		color = Color(data["color"])


func _ready() -> void:
	_noise.seed = randi()
	_base_energy = _light.energy
	_light.color = color
	if has_node("Sprite"):
		$Sprite/Flame.modulate = color.lightened(0.3)


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	_light.energy = _base_energy * (1.0 + _noise.get_noise_1d(_time * 10.0) * flicker_strength * 2.0)
