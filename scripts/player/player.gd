class_name Player
extends CharacterBody2D
## Девочка-душа. Бег, прыжок (с запасом «койот-времени»), двойной прыжок
## и рывок после прокачки, вспышка света как атака, взаимодействие с предметами.
## Числа берутся из GameState.get_stat(), то есть из data/player.json + улучшений.

signal focus_changed(target: Interactable)
signal died

const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const ACCELERATION := 1400.0
const FRICTION := 1800.0
const ATTACK_TIME := 0.15
const ATTACK_COOLDOWN := 0.35

## Ниже этой высоты героиня считается упавшей в пропасть.
var kill_y := 100000.0
var input_enabled := true
var focused: Interactable = null

var _facing := 1.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _jumps_left := 0
var _dashes_left := 0
var _dash_timer := 0.0
var _attack_timer := 0.0
var _attack_cooldown := 0.0
var _invulnerable := 0.0
var _jumping := false
var _dead := false

@onready var _sprite: Sprite2D = $Sprite
@onready var _interact_area: Area2D = $InteractArea
@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_flash: Sprite2D = $AttackArea/Flash
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	add_to_group("player")
	_attack_flash.visible = false


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_tick_timers(delta)
	var gravity := GameState.get_stat("gravity")
	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0

	if is_on_floor():
		_coyote = COYOTE_TIME
		_jumps_left = int(GameState.get_stat("extra_jumps"))
		_dashes_left = int(GameState.get_stat("dash_charges"))

	if input_enabled and Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	if input_enabled and Input.is_action_just_pressed("dash"):
		_try_dash()
	if input_enabled and Input.is_action_just_pressed("attack"):
		_try_attack()

	if _dash_timer > 0.0:
		velocity = Vector2(_facing * GameState.get_stat("dash_speed"), 0.0)
	else:
		velocity.y += gravity * delta
		var speed := GameState.get_stat("move_speed")
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, direction * speed, ACCELERATION * delta)
			_facing = signf(direction)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		_handle_jump()

	move_and_slide()
	_update_visuals(delta)
	_update_focus()
	if global_position.y > kill_y:
		die()


func _tick_timers(delta: float) -> void:
	_coyote -= delta
	_jump_buffer -= delta
	_dash_timer -= delta
	_attack_cooldown -= delta
	_invulnerable -= delta
	if _attack_timer > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_area.monitoring = false
			_attack_flash.visible = false


func _handle_jump() -> void:
	var jump_velocity := GameState.get_stat("jump_velocity")
	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			velocity.y = -jump_velocity
			_coyote = 0.0
			_jump_buffer = 0.0
			_jumping = true
		elif _jumps_left > 0:
			velocity.y = -jump_velocity * 0.9
			_jumps_left -= 1
			_jump_buffer = 0.0
			_jumping = true
			_sprite.scale = Vector2(0.8, 1.2)
	# Отпустила кнопку раньше: прыжок ниже.
	if _jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y *= 0.5
		_jumping = false
	elif velocity.y >= 0.0:
		_jumping = false


func _try_dash() -> void:
	if _dashes_left <= 0 or _dash_timer > 0.0:
		return
	_dashes_left -= 1
	_dash_timer = GameState.get_stat("dash_time")
	_invulnerable = max(_invulnerable, _dash_timer)


func _try_attack() -> void:
	if _attack_cooldown > 0.0:
		return
	_attack_cooldown = ATTACK_COOLDOWN
	_attack_timer = ATTACK_TIME
	_attack_area.monitoring = true
	_attack_flash.visible = true
	# Ждём кадр физики, чтобы область успела найти врагов.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var damage := int(GameState.get_stat("attack_damage"))
	for body in _attack_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(damage, global_position)


func _update_visuals(delta: float) -> void:
	_sprite.flip_h = _facing < 0.0
	_attack_area.scale.x = _facing
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, 10.0 * delta)
	# Мерцание во время неуязвимости
	_sprite.modulate.a = 0.4 if _invulnerable > 0.0 and int(_invulnerable * 20.0) % 2 == 0 else 1.0
	_glow.energy = 0.9 + sin(Time.get_ticks_msec() * 0.003) * 0.1


func _update_focus() -> void:
	if focused != null and not is_instance_valid(focused):
		focused = null
	var best: Interactable = null
	var best_distance := INF
	for area in _interact_area.get_overlapping_areas():
		if area is Interactable and area.is_available():
			var distance := global_position.distance_squared_to(area.global_position)
			if distance < best_distance:
				best = area
				best_distance = distance
	if best != focused:
		focused = best
		focus_changed.emit(best)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and focused != null:
		try_interact()
		get_viewport().set_input_as_handled()


func try_interact() -> void:
	if input_enabled and not _dead and focused != null and is_instance_valid(focused):
		focused.interact(self)


## Урон от врага или шипов. from: откуда пришёл удар (для отбрасывания).
func hurt(amount: int, from: Vector2) -> void:
	if _invulnerable > 0.0 or _dead:
		return
	_invulnerable = GameState.get_stat("invulnerable_time")
	GameState.damage(amount)
	var push := signf(global_position.x - from.x)
	if push == 0.0:
		push = -_facing
	velocity = Vector2(push * 260.0, -280.0)
	_dash_timer = 0.0
	if GameState.hp <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	input_enabled = false
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.5)
	died.emit()
