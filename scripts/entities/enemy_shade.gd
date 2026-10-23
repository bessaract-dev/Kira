extends CharacterBody2D
## Враг-тень: ходит туда-сюда, разворачивается у стен и обрывов,
## ранит героиню при касании. После победы даёт осколки памяти.

@export var speed := 50.0
@export var max_hp := 2
@export var shard_reward := 1
@export var gravity := 1200.0

var _direction := -1.0
var _hp := 0
var _stun := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _ledge_ray: RayCast2D = $LedgeRay
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	if _stun > 0.0:
		_stun -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	else:
		_ledge_ray.position.x = 12.0 * _direction
		if is_on_floor() and (is_on_wall() or not _ledge_ray.is_colliding()):
			_direction *= -1.0
			_ledge_ray.position.x = 12.0 * _direction
		velocity.x = _direction * speed
	move_and_slide()
	_sprite.flip_h = _direction > 0.0
	_sprite.position.y = -16.0 + sin(Time.get_ticks_msec() * 0.006) * 2.0
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			body.hurt(1, global_position)


func take_hit(damage: int, from: Vector2) -> void:
	_hp -= damage
	_stun = 0.3
	velocity = Vector2(signf(global_position.x - from.x) * 220.0, -150.0)
	_sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if _hp <= 0:
		_die()


func _die() -> void:
	GameState.add_shards(shard_reward)
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 0.2), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
