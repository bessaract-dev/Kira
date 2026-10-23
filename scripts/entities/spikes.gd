extends Area2D
## Шипы: ранят Киру, пока она их касается.

@export var damage := 1


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body is Player:
			body.hurt(damage, global_position + Vector2(0, 24))
