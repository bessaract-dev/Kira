extends CharacterBody2D
## Заводная кукла. Ходит по полу, у стен и обрывов разворачивается.
## Состояния: бесцельно бродит, замечает Киру и бежит к ней (у края обрыва ждёт),
## вблизи бросается и царапает, от удара цепью отлетает, а в конце разваливается.
## Кадры: assets/characters/doll/doll_frames.tres (анимации idle, chase, attack, hurt, death).
## Если их нет, остаётся временная картинка.

enum State { WANDER, CHASE, ATTACK, HURT, DEATH }

const FRAMES_PATH := "res://assets/characters/doll/doll_frames.tres"

@export var max_hp := 1
@export var shard_reward := 1
@export var gravity := 1200.0
## Скорость, когда просто бродит, и когда бежит к Кире
@export var wander_speed := 30.0
@export var chase_speed := 150.0
## На каком расстоянии замечает Киру и на каком теряет
@export var sight_range := 180.0
@export var lose_range := 260.0
## С какого расстояния бросается
@export var attack_range := 30.0
## Длительность броска, доля броска, когда он ранит, и пауза после
@export var attack_time := 0.7
@export var attack_hit_from := 0.3
@export var attack_hit_to := 0.65
@export var attack_cooldown := 0.8
@export var hurt_time := 0.4
@export var death_time := 1.0
@export var damage := 1

var state := State.WANDER
var _hp := 0
var _direction := -1.0
var _state_time := 0.0
var _cooldown := 0.0
## Пауза на месте во время прогулки
var _pause := 0.0
## Кадры куклы нарисованы лицом вправо
var _anim: AnimatedSprite2D = null

@onready var _sprite: Sprite2D = $Sprite
@onready var _ledge_ray: RayCast2D = $LedgeRay
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")
	if ResourceLoader.exists(FRAMES_PATH):
		_setup_animation(load(FRAMES_PATH))


func _setup_animation(frames: SpriteFrames) -> void:
	var names := frames.get_animation_names()
	if names.is_empty():
		return
	_anim = AnimatedSprite2D.new()
	_anim.name = "Animated"
	_anim.sprite_frames = frames
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var height := float(frames.get_frame_texture(names[0], 0).get_height())
	var target: float = frames.get_meta("height_px", 32.0)
	_anim.scale = Vector2.ONE * (target / height)
	_anim.offset.y = -height / 2.0
	add_child(_anim)
	move_child(_anim, _sprite.get_index())
	_sprite.visible = false
	_play("idle")


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	_state_time += delta
	_cooldown -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		State.WANDER:
			_wander(delta, player)
		State.CHASE:
			_chase(player)
		State.ATTACK:
			_attack(delta)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _state_time >= hurt_time:
				_set_state(State.CHASE if player != null else State.WANDER)
		State.DEATH:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	move_and_slide()
	_update_visual()


func _wander(delta: float, player: Node2D) -> void:
	if _pause > 0.0:
		_pause -= delta
		velocity.x = 0.0
	else:
		if is_on_floor() and (is_on_wall() or not _ground_ahead()):
			_direction *= -1.0
		velocity.x = _direction * wander_speed
		# Иногда останавливается и стоит
		if randf() < delta * 0.25:
			_pause = randf_range(0.8, 2.0)
	if player != null and _sees(player, sight_range):
		_set_state(State.CHASE)


func _chase(player: Node2D) -> void:
	if player == null or not _sees(player, lose_range):
		_set_state(State.WANDER)
		return
	var offset := player.global_position - global_position
	if offset.x != 0.0:
		_direction = signf(offset.x)
	if absf(offset.x) <= attack_range and _cooldown <= 0.0:
		_set_state(State.ATTACK)
		return
	# Не бросается с обрыва: у края ждёт
	velocity.x = _direction * chase_speed if _ground_ahead() else 0.0


func _attack(delta: float) -> void:
	var t := _state_time / attack_time
	if t < attack_hit_from:
		velocity.x = move_toward(velocity.x, -_direction * 20.0, 600.0 * delta)
	elif t < attack_hit_to:
		# Бросок вперёд, в это время удар ранит
		velocity.x = _direction * chase_speed * 1.3 if _ground_ahead() else 0.0
		for body in _hitbox.get_overlapping_bodies():
			if body is Player:
				body.hurt(damage, global_position)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if t >= 1.0:
		_cooldown = attack_cooldown
		_set_state(State.CHASE)


func _ground_ahead() -> bool:
	_ledge_ray.position.x = 12.0 * _direction
	_ledge_ray.force_raycast_update()
	return _ledge_ray.is_colliding()


## Кукла видит Киру, только если та примерно на одном с ней уровне.
func _sees(player: Node2D, distance: float) -> bool:
	var offset := player.global_position - global_position
	return absf(offset.x) <= distance and absf(offset.y) < 40.0


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _update_visual() -> void:
	if _anim != null:
		_anim.flip_h = _direction < 0.0
		_play(_animation_for_state())
	else:
		# Временная картинка нарисована лицом влево
		_sprite.flip_h = _direction > 0.0


func _animation_for_state() -> String:
	match state:
		State.CHASE:
			return "chase" if absf(velocity.x) > 1.0 else "idle"
		State.ATTACK:
			return "attack"
		State.HURT:
			return "hurt"
		State.DEATH:
			return "death"
	return "idle"


func _play(animation: String) -> void:
	var frames := _anim.sprite_frames
	if not frames.has_animation(animation):
		animation = "idle" if frames.has_animation("idle") else frames.get_animation_names()[0]
	if _anim.animation != animation or not _anim.is_playing():
		_anim.play(animation)
		# Разовые анимации растягиваем на длительность состояния
		var length := _state_length(animation)
		if length > 0.0:
			var count := frames.get_frame_count(animation)
			_anim.speed_scale = (count / frames.get_animation_speed(animation)) / length
		else:
			_anim.speed_scale = 1.0


func _state_length(animation: String) -> float:
	match animation:
		"attack":
			return attack_time
		"hurt":
			return hurt_time
		"death":
			return death_time
	return 0.0


func take_hit(amount: int, from: Vector2) -> void:
	if state == State.DEATH:
		return
	_hp -= amount
	velocity = Vector2(signf(global_position.x - from.x) * 200.0, -140.0)
	if from.x != global_position.x:
		_direction = signf(from.x - global_position.x)
	Sound.play("enemy_hit")
	var target: CanvasItem = _anim if _anim != null else _sprite
	target.modulate = Color(3, 3, 3)
	create_tween().tween_property(target, "modulate", Color.WHITE, 0.2)
	if _hp <= 0:
		_die()
	else:
		_set_state(State.HURT)


func _die() -> void:
	_set_state(State.DEATH)
	GameState.add_shards(shard_reward)
	Sound.play("enemy_die")
	$CollisionShape2D.set_deferred("disabled", true)
	_hitbox.set_deferred("monitoring", false)
	var tween := create_tween()
	if _anim == null:
		tween.tween_property(self, "scale", Vector2(1.5, 0.2), 0.25)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	else:
		tween.tween_interval(death_time)
		tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)
