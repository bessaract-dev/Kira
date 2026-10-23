extends CharacterBody2D
## Общий скрипт врагов: ходит туда-сюда, разворачивается у стен и обрывов,
## ранит Киру при касании. Разные враги (душа, скелет, кукла) это одна логика
## с разными числами в сцене. После победы даёт осколки памяти.

@export var speed := 40.0
@export var max_hp := 1
@export var shard_reward := 1
@export var gravity := 1200.0
## Если больше нуля, враг бросается на Киру, когда видит её.
@export var charge_speed := 0.0
@export var sight_range := 160.0
## Тяжёлых врагов (скелет в броне) почти не отбрасывает.
@export var heavy := false
## Лёгкое покачивание спрайта (души парят).
@export var hover := false

var _direction := -1.0
var _hp := 0
var _stun := 0.0
var _sprite_base_y := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _ledge_ray: RayCast2D = $LedgeRay
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hp = max_hp
	_sprite_base_y = _sprite.position.y
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
		velocity.x = _direction * _current_speed()
	move_and_slide()
	_sprite.flip_h = _direction > 0.0
	if hover:
		_sprite.position.y = _sprite_base_y + sin(Time.get_ticks_msec() * 0.005) * 2.0
	for body in _hitbox.get_overlapping_bodies():
		if body is Player:
			body.hurt(1, global_position)


func _current_speed() -> float:
	if charge_speed <= 0.0:
		return speed
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return speed
	var offset := player.global_position - global_position
	if absf(offset.x) < sight_range and absf(offset.y) < 40.0:
		if offset.x != 0.0:
			_direction = signf(offset.x)
		# Не бросаемся с обрыва: у края ждём.
		_ledge_ray.position.x = 12.0 * _direction
		_ledge_ray.force_raycast_update()
		return charge_speed if _ledge_ray.is_colliding() else 0.0
	return speed


func take_hit(damage: int, from: Vector2) -> void:
	_hp -= damage
	_stun = 0.15 if heavy else 0.3
	var push := 60.0 if heavy else 220.0
	velocity = Vector2(signf(global_position.x - from.x) * push, -80.0 if heavy else -150.0)
	Sound.play("enemy_hit")
	_sprite.modulate = Color(3, 3, 3)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	if _hp <= 0:
		_die()


func _die() -> void:
	GameState.add_shards(shard_reward)
	Sound.play("enemy_die")
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	_hitbox.set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 0.2), 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
