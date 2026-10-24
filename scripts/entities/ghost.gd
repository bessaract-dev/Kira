extends CharacterBody2D
## Призрак (душа подростка). Летает и проходит сквозь стены.
## Состояния: бесцельно парит около своего места, замечает Киру и летит к ней,
## вблизи замахивается и бьёт, от удара цепью вздрагивает, а в конце рассеивается.
## Кадры берутся из assets/characters/ghost/ghost_frames.tres
## (анимации idle, chase, attack, hurt, death); если их нет, остаётся временная картинка.

enum State { WANDER, CHASE, ATTACK, HURT, DEATH }

const FRAMES_PATH := "res://assets/characters/ghost/ghost_frames.tres"

@export var max_hp := 1
@export var shard_reward := 1
## Скорость, когда просто парит
@export var wander_speed := 25.0
## Скорость погони за Кирой
@export var chase_speed := 75.0
## На каком расстоянии замечает Киру и на каком теряет
@export var sight_range := 170.0
@export var lose_range := 300.0
## Дальше этого от своего места не улетает, возвращается
@export var leash_range := 420.0
## С какого расстояния бьёт
@export var attack_range := 34.0
## Длительность удара, доля удара, когда он ранит, и пауза после удара
@export var attack_time := 0.8
@export var attack_hit_from := 0.4
@export var attack_hit_to := 0.7
@export var attack_cooldown := 0.9
@export var hurt_time := 0.4
@export var death_time := 1.2
@export var damage := 1

var state := State.WANDER
var _hp := 0
var _home := Vector2.ZERO
var _wander_target := Vector2.ZERO
var _state_time := 0.0
var _cooldown := 0.0
var _facing := 1.0
var _attack_dir := Vector2.RIGHT
## Кадры призрака нарисованы лицом вправо
var _anim: AnimatedSprite2D = null
var _sprite_base_y := 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _hitbox: Area2D = $Hitbox


func _ready() -> void:
	_hp = max_hp
	_home = global_position
	_wander_target = _home
	_sprite_base_y = _sprite.position.y
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
	var target: float = frames.get_meta("height_px", 56.0)
	_anim.scale = Vector2.ONE * (target / height)
	_anim.offset.y = -height / 2.0
	add_child(_anim)
	move_child(_anim, _sprite.get_index())
	_sprite.visible = false
	_play("idle")


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cooldown -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	match state:
		State.WANDER:
			_wander(delta, player)
		State.CHASE:
			_chase(delta, player)
		State.ATTACK:
			_attack(delta)
		State.HURT:
			velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
			if _state_time >= hurt_time:
				_set_state(State.CHASE if player != null else State.WANDER)
		State.DEATH:
			velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
	move_and_slide()
	if absf(velocity.x) > 5.0 and state != State.ATTACK and state != State.HURT:
		_facing = signf(velocity.x)
	_update_visual()


func _wander(delta: float, player: Node2D) -> void:
	if global_position.distance_to(_wander_target) < 6.0 or _state_time > 4.0:
		# Новая случайная точка рядом с домом
		_wander_target = _home + Vector2(randf_range(-70.0, 70.0), randf_range(-30.0, 0.0))
		_state_time = 0.0
	var to_target := _wander_target - global_position
	velocity = velocity.move_toward(to_target.normalized() * wander_speed, 80.0 * delta)
	if player != null and _sees(player, sight_range):
		_set_state(State.CHASE)


func _chase(delta: float, player: Node2D) -> void:
	if player == null or not _sees(player, lose_range) \
			or global_position.distance_to(_home) > leash_range:
		_set_state(State.WANDER)
		_wander_target = _home
		return
	var target := _aim_point(player)
	var to_target := target - global_position
	if to_target.length() <= attack_range and _cooldown <= 0.0:
		_attack_dir = to_target.normalized()
		_facing = signf(to_target.x) if to_target.x != 0.0 else _facing
		_set_state(State.ATTACK)
		return
	velocity = velocity.move_toward(to_target.normalized() * chase_speed, 260.0 * delta)


func _attack(delta: float) -> void:
	var t := _state_time / attack_time
	if t < attack_hit_from:
		# Замах: чуть отлетает назад
		velocity = velocity.move_toward(-_attack_dir * 30.0, 400.0 * delta)
	elif t < attack_hit_to:
		# Бросок вперёд, в это время удар ранит
		velocity = _attack_dir * chase_speed * 2.2
		for body in _hitbox.get_overlapping_bodies():
			if body is Player:
				body.hurt(damage, global_position)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
	if t >= 1.0:
		_cooldown = attack_cooldown
		_set_state(State.CHASE)


## Видит ли Киру: призраки смотрят сквозь стены, важна только дистанция.
func _sees(player: Node2D, distance: float) -> bool:
	return _aim_point(player).distance_to(global_position) <= distance


## Точка, куда летит призрак: на уровне груди Киры.
func _aim_point(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0, 4)


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _update_visual() -> void:
	var bob := sin(Time.get_ticks_msec() * 0.004) * 2.0
	if _anim != null:
		_anim.flip_h = _facing < 0.0
		_anim.position.y = bob if state == State.WANDER else 0.0
		_play(_animation_for_state())
	else:
		# Кадры нарисованы лицом влево
		_sprite.flip_h = _facing > 0.0
		_sprite.position.y = _sprite_base_y + bob


func _animation_for_state() -> String:
	match state:
		State.CHASE:
			return "chase"
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
	velocity = Vector2(signf(global_position.x - from.x) * 180.0, -40.0)
	_facing = signf(from.x - global_position.x) if from.x != global_position.x else _facing
	Sound.play("enemy_hit")
	var target: CanvasItem = _anim if _anim != null else _sprite
	target.modulate = Color(3, 3, 3)
	create_tween().tween_property(target, "modulate", Color.WHITE, 0.2)
	if _hp <= 0:
		_die()
	else:
		_set_state(State.HURT)
		_cooldown = attack_cooldown * 0.5


func _die() -> void:
	_set_state(State.DEATH)
	GameState.add_shards(shard_reward)
	Sound.play("enemy_die")
	$CollisionShape2D.set_deferred("disabled", true)
	_hitbox.set_deferred("monitoring", false)
	var tween := create_tween()
	if _anim == null:
		# Без кадров смерти просто рассеивается
		tween.tween_property(self, "scale", Vector2(1.4, 0.3), 0.3)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	else:
		tween.tween_interval(death_time * 0.7)
		tween.tween_property(self, "modulate:a", 0.0, death_time * 0.3)
	tween.tween_callback(queue_free)
