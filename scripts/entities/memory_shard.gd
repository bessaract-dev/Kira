extends Area2D
## Осколок памяти: валюта для прокачки. Подбирается касанием.

var persist_key := ""
var _time := randf() * TAU

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta * 3.0
	_sprite.position.y = -14.0 + sin(_time) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	GameState.add_shards(1)
	Sound.play("shard")
	if persist_key != "":
		GameState.mark_picked(persist_key)
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)
