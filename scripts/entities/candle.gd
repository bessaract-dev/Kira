extends Node2D
## Мерцающий источник света (свеча, факел).

@export var flicker_strength := 0.2
@export var flicker_speed := 6.0

var _noise := FastNoiseLite.new()
var _time := randf() * 100.0
var _base_energy := 1.0

@onready var _light: PointLight2D = $Light


func _ready() -> void:
	_noise.seed = randi()
	_base_energy = _light.energy


func _process(delta: float) -> void:
	_time += delta * flicker_speed
	_light.energy = _base_energy * (1.0 + _noise.get_noise_1d(_time * 10.0) * flicker_strength * 2.0)
