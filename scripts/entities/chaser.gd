extends Area2D
## Погоня: стена тьмы с белыми глазами ползёт вправо и забирает Киру при касании.
## Стартует с задержкой и ждёт, пока Кира не сдвинется с места.

@export var speed := 85.0
@export var start_delay := 1.5
## Дальше этой точки (в пикселях) тьма не идёт: это правая стена уровня.
var stop_x := INF

var _delay := 0.0


func configure(data: Dictionary) -> void:
	speed = data.get("speed", speed)
	start_delay = data.get("delay", start_delay)


func _ready() -> void:
	add_to_group("chaser_group")
	_delay = start_delay
	body_entered.connect(_on_body_entered)


## Уровень растягивает тьму на всю высоту и ставит её позади Киры.
func place(left_x: float, height: float) -> void:
	global_position = Vector2(left_x, 0.0)
	$Sprite.scale.y = height / $Sprite.texture.get_height()
	$CollisionShape2D.shape.size.y = height
	$CollisionShape2D.position.y = height / 2.0


func _physics_process(delta: float) -> void:
	if _delay > 0.0:
		_delay -= delta
		return
	if global_position.x < stop_x:
		global_position.x += speed * delta
	for body in get_overlapping_bodies():
		if body is Player:
			body.die()


func _on_body_entered(body: Node2D) -> void:
	if body is Player and _delay <= 0.0:
		body.die()
