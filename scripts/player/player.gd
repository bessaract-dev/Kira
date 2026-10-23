class_name Player
extends CharacterBody2D
## Кира, девочка-душа в цепях.
## Бег и прыжок есть всегда. Цепи дают три приёма: хлыст (вблизи), бросок (вдаль)
## и крюк (перелёт к железным кольцам). Буквы имени разбивают цепи и забирают приёмы,
## а когда разбита последняя, Кира может отталкиваться от стен.
## Числа берутся из GameState.get_stat(), то есть из data/player.json + улучшений.

signal focus_changed(target: Interactable)
signal died

const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const ACCELERATION := 1400.0
const FRICTION := 1800.0
const WHIP_TIME := 0.15
const WHIP_COOLDOWN := 0.35
const THROW_COOLDOWN := 0.5
const HOOK_MAX_TIME := 0.9
const WALL_JUMP_LOCK := 0.18
## Сколько секунд после касания стены от неё ещё можно оттолкнуться.
const WALL_COYOTE := 0.12
## Сколько секунд после крюка Кира летит по инерции быстрее обычного бега.
const HOOK_MOMENTUM_TIME := 0.4
const BOLT_SCENE := preload("res://scenes/player/chain_bolt.tscn")
## Покадровая анимация Киры. Если файла нет, рисуется временная картинка.
## Имена анимаций: idle, run, jump, fall, land, whip, throw, hook, wall_slide, hurt, death.
## Вариант без цепей можно добавить с окончанием _free (например run_free).
const FRAMES_PATH := "res://assets/characters/kira/kira_frames.tres"
const ACTION_ANIM_TIME := 0.25

## Ниже этой высоты Кира считается упавшей в пропасть.
var kill_y := 100000.0
var input_enabled := true
var focused: Interactable = null

var _facing := 1.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _jumping := false
var _whip_timer := 0.0
var _whip_cooldown := 0.0
var _throw_cooldown := 0.0
var _invulnerable := 0.0
var _wall_lock := 0.0
var _momentum := 0.0
var _wall_timer := 0.0
var _wall_normal := 0.0
var _hook_target: Node2D = null
var _hook_time := 0.0
var _dead := false
var _anim: AnimatedSprite2D = null
var _hurt_timer := 0.0
var _throw_anim_timer := 0.0
var _land_timer := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _chains: Sprite2D = $Sprite/Chains
@onready var _interact_area: Area2D = $InteractArea
@onready var _whip_area: Area2D = $WhipArea
@onready var _whip_line: Line2D = $WhipArea/WhipLine
@onready var _hook_line: Line2D = $HookLine
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	add_to_group("player")
	_whip_line.visible = false
	_hook_line.visible = false
	GameState.abilities_changed.connect(_on_abilities_changed)
	_on_abilities_changed()
	if ResourceLoader.exists(FRAMES_PATH):
		_setup_animation(load(FRAMES_PATH))


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_tick_timers(delta)
	var direction := Input.get_axis("move_left", "move_right") if input_enabled else 0.0

	if is_on_floor():
		_coyote = COYOTE_TIME
	if input_enabled:
		if Input.is_action_just_pressed("jump"):
			_jump_buffer = JUMP_BUFFER
		if Input.is_action_just_pressed("attack"):
			_try_whip()
		if Input.is_action_just_pressed("throw"):
			_try_throw()
		if Input.is_action_just_pressed("hook"):
			_try_hook()

	if _hook_target != null:
		_process_hook(delta)
	else:
		_process_walk(direction, delta)
	var was_on_floor := is_on_floor()
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_floor() and not was_on_floor and fall_speed > 300.0:
		Sound.play("land")
		_land_timer = 0.15
	_update_visuals(delta)
	_update_focus()
	if global_position.y > kill_y:
		die()


func _tick_timers(delta: float) -> void:
	_coyote -= delta
	_jump_buffer -= delta
	_whip_cooldown -= delta
	_throw_cooldown -= delta
	_invulnerable -= delta
	_wall_lock -= delta
	_momentum -= delta
	_wall_timer -= delta
	_hurt_timer -= delta
	_throw_anim_timer -= delta
	_land_timer -= delta
	if _whip_timer > 0.0:
		_whip_timer -= delta
		if _whip_timer <= 0.0:
			_whip_area.monitoring = false
			_whip_line.visible = false


func _process_walk(direction: float, delta: float) -> void:
	velocity.y += GameState.get_stat("gravity") * delta
	var speed := GameState.get_stat("move_speed")
	if _momentum > 0.0 and not is_on_floor():
		# Полёт после крюка: не тормозим, только чуть поворачиваем.
		if direction != 0.0:
			_facing = signf(direction)
	elif _wall_lock <= 0.0:
		if direction != 0.0:
			velocity.x = move_toward(velocity.x, direction * speed, ACCELERATION * delta)
			_facing = signf(direction)
		else:
			velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)

	if _can_wall_jump() and is_on_wall_only():
		_wall_timer = WALL_COYOTE
		_wall_normal = get_wall_normal().x
		if direction != 0.0:
			# Скольжение по стене
			velocity.y = minf(velocity.y, GameState.get_stat("wall_slide_speed"))

	var jump_velocity := GameState.get_stat("jump_velocity")
	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			velocity.y = -jump_velocity
			_coyote = 0.0
			_jump_buffer = 0.0
			_jumping = true
			Sound.play("jump")
		elif _wall_timer > 0.0:
			var away := _wall_normal
			_wall_timer = 0.0
			velocity = Vector2(away * GameState.get_stat("wall_jump_push"), -jump_velocity)
			_facing = signf(away)
			_wall_lock = WALL_JUMP_LOCK
			_jump_buffer = 0.0
			_jumping = true
			_sprite.scale = Vector2(0.8, 1.2)
			Sound.play("wall_jump")
	# Отпустила кнопку раньше: прыжок ниже.
	if _jumping and velocity.y < 0.0 and not Input.is_action_pressed("jump"):
		velocity.y *= 0.5
		_jumping = false
	elif velocity.y >= 0.0:
		_jumping = false


func _can_wall_jump() -> bool:
	return GameState.has_ability("wall_jump")


# --- Хлыст ---

func _try_whip() -> void:
	if not GameState.has_ability("whip") or _whip_cooldown > 0.0:
		return
	_whip_cooldown = WHIP_COOLDOWN
	_whip_timer = WHIP_TIME
	_whip_area.monitoring = true
	_whip_line.visible = true
	Sound.play("whip")
	# Ждём кадр физики, чтобы область успела найти врагов.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var damage := int(GameState.get_stat("whip_damage"))
	for body in _whip_area.get_overlapping_bodies():
		if body.has_method("take_hit"):
			body.take_hit(damage, global_position)


# --- Бросок ---

func _try_throw() -> void:
	if not GameState.has_ability("throw") or _throw_cooldown > 0.0:
		return
	_throw_cooldown = THROW_COOLDOWN
	_throw_anim_timer = ACTION_ANIM_TIME
	Sound.play("throw")
	var bolt := BOLT_SCENE.instantiate()
	bolt.global_position = global_position + Vector2(10.0 * _facing, -24.0)
	bolt.direction = _facing
	bolt.owner_player = self
	get_parent().add_child(bolt)


# --- Крюк ---

func _try_hook() -> void:
	if not GameState.has_ability("hook") or _hook_target != null:
		return
	var target := _find_hook_point()
	if target == null:
		return
	_hook_target = target
	_hook_time = 0.0
	_hook_line.visible = true
	Sound.play("hook")


func _find_hook_point() -> Node2D:
	var best: Node2D = null
	var best_score := INF
	var hand := global_position + Vector2(0, -24)
	var max_range := GameState.get_stat("hook_range")
	for point: Node2D in get_tree().get_nodes_in_group("hook_point"):
		var offset := point.global_position - hand
		if offset.length() > max_range or offset.y > 8.0:
			continue
		# Кольцо впереди предпочтительнее кольца сзади.
		var score := offset.length() + (0.0 if signf(offset.x) == _facing else 120.0)
		if score < best_score:
			best = point
			best_score = score
	return best


func _process_hook(delta: float) -> void:
	_hook_time += delta
	var hand := global_position + Vector2(0, -24)
	var offset := _hook_target.global_position - hand
	var speed := GameState.get_stat("hook_speed")
	if offset.length() < 18.0 or _hook_time > HOOK_MAX_TIME or (_hook_time > 0.1 and get_slide_collision_count() > 0):
		_release_hook(offset.normalized() * speed)
		return
	velocity = offset.normalized() * speed
	if offset.x != 0.0:
		_facing = signf(offset.x)


func _release_hook(last_velocity: Vector2) -> void:
	_hook_target = null
	_hook_line.visible = false
	# Сохраняем разгон вперёд и подбрасываем вверх, чтобы долететь дальше кольца.
	velocity = Vector2(last_velocity.x * 0.75, minf(last_velocity.y * 0.4, -340.0))
	_momentum = HOOK_MOMENTUM_TIME
	_coyote = 0.0


# --- Внешний вид ---

func _update_visuals(delta: float) -> void:
	_sprite.flip_h = _facing < 0.0
	_whip_area.scale.x = _facing
	_sprite.scale = _sprite.scale.lerp(Vector2.ONE, 10.0 * delta)
	var blink := 0.4 if _invulnerable > 0.0 and int(_invulnerable * 20.0) % 2 == 0 else 1.0
	_sprite.modulate.a = blink
	if _anim:
		_anim.flip_h = _facing < 0.0
		_anim.modulate.a = blink
		_play(_pick_animation())
	_glow.energy = 0.9 + sin(Time.get_ticks_msec() * 0.003) * 0.1
	if _hook_target != null:
		_hook_line.points = [Vector2(0, -24), to_local(_hook_target.global_position)]


# --- Покадровая анимация ---

func _setup_animation(frames: SpriteFrames) -> void:
	var names := frames.get_animation_names()
	if names.is_empty():
		return
	_anim = AnimatedSprite2D.new()
	_anim.name = "Animated"
	_anim.sprite_frames = frames
	# Рисованные кадры сильно уменьшаются: сглаживаем, а не берём пиксели как есть.
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var height := float(frames.get_frame_texture(names[0], 0).get_height())
	# Высота кадра в игре в пикселях мира (метаданные height_px у SpriteFrames, по умолчанию 48).
	var target: float = frames.get_meta("height_px", 48.0)
	_anim.scale = Vector2.ONE * (target / height)
	_anim.offset.y = -height / 2.0
	add_child(_anim)
	move_child(_anim, _sprite.get_index())
	_sprite.visible = false


func _pick_animation() -> String:
	if _dead:
		return "death"
	if _hurt_timer > 0.0:
		return "hurt"
	if _hook_target != null:
		return "hook"
	if _whip_timer > 0.0:
		return "whip"
	if _throw_anim_timer > 0.0:
		return "throw"
	if not is_on_floor():
		if is_on_wall_only() and velocity.y > 0.0:
			return "wall_slide"
		return "jump" if velocity.y < 0.0 else "fall"
	if absf(velocity.x) > 10.0:
		return "run"
	return "land" if _land_timer > 0.0 else "idle"


func _play(animation: String) -> void:
	var frames := _anim.sprite_frames
	if GameState.has_ability("free") and frames.has_animation(animation + "_free"):
		animation += "_free"
	if not frames.has_animation(animation):
		animation = "idle" if frames.has_animation("idle") else frames.get_animation_names()[0]
	if _anim.animation != animation or not _anim.is_playing():
		_anim.play(animation)


func _on_abilities_changed() -> void:
	_chains.visible = not GameState.has_ability("free")


# --- Взаимодействие ---

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


# --- Урон ---

## Урон от врага или шипов. from: откуда пришёл удар (для отбрасывания).
func hurt(amount: int, from: Vector2) -> void:
	if _invulnerable > 0.0 or _dead:
		return
	_invulnerable = GameState.get_stat("invulnerable_time")
	GameState.damage(amount)
	var push := signf(global_position.x - from.x)
	if push == 0.0:
		push = -_facing
	_hook_target = null
	_hook_line.visible = false
	velocity = Vector2(push * 260.0, -280.0)
	_hurt_timer = ACTION_ANIM_TIME
	Sound.play("hurt")
	if GameState.hp <= 0:
		die()


func die() -> void:
	if _dead:
		return
	_dead = true
	input_enabled = false
	_hook_line.visible = false
	Sound.play("death")
	var tween := create_tween()
	tween.tween_property(_anim if _anim else _sprite, "modulate:a", 0.0, 0.8)
	died.emit()
