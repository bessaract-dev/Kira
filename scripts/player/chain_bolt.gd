extends Area2D
## Брошенная цепь: летит вперёд, бьёт первого врага и возвращается в руку.

var direction := 1.0
var owner_player: Node2D

var _travelled := 0.0
var _returning := false

@onready var _line: Line2D = $Line


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player):
		queue_free()
		return
	var hand := owner_player.global_position + Vector2(0, -24)
	var speed := GameState.get_stat("throw_speed")
	if _returning:
		global_position = global_position.move_toward(hand, speed * 1.5 * delta)
		if global_position.distance_to(hand) < 12.0:
			queue_free()
	else:
		global_position.x += direction * speed * delta
		_travelled += speed * delta
		if _travelled >= GameState.get_stat("throw_range"):
			_returning = true
	_line.points = [to_local(hand), Vector2.ZERO]


func _on_body_entered(body: Node2D) -> void:
	if _returning:
		return
	if body.has_method("take_hit"):
		body.take_hit(int(GameState.get_stat("throw_damage")), owner_player.global_position)
	# Цепь ударилась во врага или в стену: возвращаемся.
	_returning = true
