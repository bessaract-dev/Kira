extends CharacterBody2D
## Скелет в броне. Медленно ходит по полу, у стен и обрывов разворачивается.
## Состояния: бродит, замечает Киру и марширует к ней (у края обрыва ждёт),
## вблизи рубит мечом, от удара цепью чуть отшатывается (броня тяжёлая).
## Смерть: шатается и рассыпается на кости, меч втыкается в землю,
## а череп в шлеме падает и насаживается на рукоять. Это надгробие остаётся на уровне.
## Кадры: assets/characters/skeleton/skeleton_frames.tres (анимации idle, chase, attack, hurt, death),
## части надгробия: grave_skull.png, grave_sword.png, grave_bones.png там же.
## Если кадров нет, остаётся временная картинка.

enum State { WANDER, CHASE, ATTACK, HURT, DEATH }

const FRAMES_PATH := "res://assets/characters/skeleton/skeleton_frames.tres"
const GRAVE_DIR := "res://assets/characters/skeleton/"
## Где части надгробия стоят относительно его низа (в пикселях исходной картинки)
## и какой высоты исходное надгробие
const GRAVE_PARTS := {
	"bones": Vector2(-2, -96),
	"sword": Vector2(-7, -427),
	"skull": Vector2(-22, -852),
}
const GRAVE_SOURCE_HEIGHT := 956.0
## Высота надгробия в игре
const GRAVE_HEIGHT := 50.0
## На сколько кусков по каждой стороне рассыпается тело
const CRUMBLE_GRID := 6
## Сколько скелет шатается перед тем, как рассыпаться
const SHUDDER_TIME := 0.5
## Анимации, нарисованные лицом вправо; остальные кадры скелета смотрят влево
const FACES_RIGHT := ["chase"]
## Ближе этого по горизонтали к Кире скелет не разворачивается, чтобы не дёргаться туда-сюда
const TURN_DEADZONE := 6.0

@export var max_hp := 3
@export var shard_reward := 2
@export var gravity := 1200.0
## Скорость, когда просто бродит, и когда марширует к Кире
@export var wander_speed := 22.0
@export var chase_speed := 70.0
## На каком расстоянии замечает Киру и на каком теряет
@export var sight_range := 170.0
@export var lose_range := 250.0
## С какого расстояния замахивается и докуда достаёт мечом
@export var attack_range := 36.0
@export var attack_reach := 48.0
## Длительность удара, доля удара, когда меч ранит, и пауза после
@export var attack_time := 0.9
@export var attack_hit_from := 0.62
@export var attack_hit_to := 0.95
@export var attack_cooldown := 1.0
@export var hurt_time := 0.3
@export var damage := 1

var state := State.WANDER
var _hp := 0
var _direction := -1.0
var _state_time := 0.0
var _cooldown := 0.0
var _pause := 0.0
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
	var target: float = frames.get_meta("height_px", 44.0)
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
			_attack(delta, player)
		State.HURT:
			velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
			if _state_time >= hurt_time:
				_set_state(State.CHASE if player != null else State.WANDER)
		State.DEATH:
			# Коллизия уже выключена: стоит на месте, чтобы не провалиться сквозь пол
			velocity = Vector2.ZERO
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
		if randf() < delta * 0.2:
			_pause = randf_range(1.0, 2.5)
	if player != null and _sees(player, sight_range):
		_set_state(State.CHASE)


func _chase(player: Node2D) -> void:
	if player == null or not _sees(player, lose_range):
		_set_state(State.WANDER)
		return
	var offset := player.global_position - global_position
	if absf(offset.x) > TURN_DEADZONE:
		_direction = signf(offset.x)
	if absf(offset.x) <= attack_range and _cooldown <= 0.0:
		_set_state(State.ATTACK)
		return
	# Не шагает с обрыва: у края ждёт
	velocity.x = _direction * chase_speed if _ground_ahead() else 0.0


func _attack(delta: float, player: Node2D) -> void:
	var t := _state_time / attack_time
	velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	if t >= attack_hit_from and t < attack_hit_to and player is Player:
		# Меч рубит перед скелетом
		var offset := player.global_position - global_position
		if offset.x * _direction >= -8.0 and absf(offset.x) <= attack_reach and absf(offset.y) < 36.0:
			player.hurt(damage, global_position)
	if t >= 1.0:
		_cooldown = attack_cooldown
		_set_state(State.CHASE)


func _ground_ahead() -> bool:
	_ledge_ray.position.x = 12.0 * _direction
	_ledge_ray.force_raycast_update()
	return _ledge_ray.is_colliding()


## Скелет видит Киру, только если та примерно на одном с ним уровне.
func _sees(player: Node2D, distance: float) -> bool:
	var offset := player.global_position - global_position
	return absf(offset.x) <= distance and absf(offset.y) < 40.0


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _update_visual() -> void:
	if _anim != null:
		var animation := _animation_for_state()
		var faces_right := animation in FACES_RIGHT
		_anim.flip_h = (_direction < 0.0) == faces_right
		_play(animation)
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
			return SHUDDER_TIME
	return 0.0


func take_hit(amount: int, from: Vector2) -> void:
	if state == State.DEATH:
		return
	_hp -= amount
	# Тяжёлая броня: почти не отбрасывает
	velocity = Vector2(signf(global_position.x - from.x) * 60.0, -60.0)
	if absf(from.x - global_position.x) > TURN_DEADZONE:
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
	remove_from_group("enemy")
	$CollisionShape2D.set_deferred("disabled", true)
	_hitbox.set_deferred("monitoring", false)
	# Надгробие лежит позади Киры
	z_index = -1
	if _anim != null:
		await get_tree().create_timer(SHUDDER_TIME).timeout
		set_physics_process(false)
		var body := _anim.sprite_frames.get_frame_texture(_anim.animation, _anim.frame) as AtlasTexture
		_anim.visible = false
		if body != null:
			_crumble(body, _anim.scale.x, _anim.flip_h)
	else:
		set_physics_process(false)
		_crumble(null, 1.0, false)
	_build_grave()


## Тело рассыпается: кадр режется на куски, они осыпаются на пол и гаснут.
func _crumble(frame: AtlasTexture, scale_factor: float, flipped: bool) -> void:
	var texture: Texture2D = frame.atlas if frame != null else _sprite.texture
	var region := frame.region if frame != null else Rect2(Vector2.ZERO, _sprite.texture.get_size())
	if frame == null:
		_sprite.visible = false
		flipped = _sprite.flip_h
	var cell := region.size / Vector2(CRUMBLE_GRID, CRUMBLE_GRID)
	var flip := -1.0 if flipped else 1.0
	var center := Vector2(0, -region.size.y / 2.0 * scale_factor)
	var tween := create_tween().set_parallel()
	for gx in CRUMBLE_GRID:
		for gy in CRUMBLE_GRID:
			var piece := Sprite2D.new()
			piece.texture = texture
			piece.region_enabled = true
			piece.region_rect = Rect2(region.position + cell * Vector2(gx, gy), cell)
			piece.flip_h = flipped
			piece.scale = Vector2.ONE * scale_factor
			piece.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			var local := (cell * (Vector2(gx, gy) + Vector2(0.5, 0.5)) - region.size / 2.0) * scale_factor
			local.x *= flip
			piece.position = center + local
			add_child(piece)
			# Верхние куски падают чуть позже нижних, будто скелет оседает
			var delay := (1.0 - float(gy) / CRUMBLE_GRID) * 0.15 + randf() * 0.08
			var fall_time := 0.35 + randf() * 0.15
			var land := Vector2(piece.position.x * 1.4 + randf_range(-10.0, 10.0), randf_range(-3.0, 0.0))
			# Подскок вверх на месте и падение на пол с отскоком
			tween.tween_property(piece, "position", land, fall_time) \
					.set_delay(delay).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.tween_property(piece, "rotation", randf_range(-2.5, 2.5), fall_time).set_delay(delay)
			tween.tween_property(piece, "modulate:a", 0.0, 0.4).set_delay(1.1 + randf() * 0.3)
			tween.tween_callback(piece.queue_free).set_delay(1.9)


## Меч взлетает и втыкается в землю, череп подлетает и насаживается на рукоять, у подножия кости.
func _build_grave() -> void:
	var textures := {}
	for part in GRAVE_PARTS:
		var path: String = GRAVE_DIR + "grave_%s.png" % part
		if not ResourceLoader.exists(path):
			queue_free()
			return
		textures[part] = load(path)
	var k := GRAVE_HEIGHT / GRAVE_SOURCE_HEIGHT
	# Надгробие нарисовано с черепом лицом влево, как и сам скелет
	var flip := 1.0 if _direction < 0.0 else -1.0
	var sprites := {}
	for part in GRAVE_PARTS:
		var sprite := Sprite2D.new()
		sprite.texture = textures[part]
		sprite.scale = Vector2.ONE * k
		sprite.flip_h = flip < 0.0
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite)
		sprites[part] = sprite
	var final := {}
	for part in GRAVE_PARTS:
		var offset: Vector2 = GRAVE_PARTS[part] * k
		final[part] = Vector2(offset.x * flip, offset.y)
	var tween := create_tween().set_parallel()
	# Кости проступают у ног, пока тело осыпается
	var bones: Sprite2D = sprites["bones"]
	bones.position = final["bones"]
	bones.modulate.a = 0.0
	tween.tween_property(bones, "modulate:a", 1.0, 0.3).set_delay(0.35)
	# Меч: из руки вверх с вращением, потом остриём вниз в землю
	var sword: Sprite2D = sprites["sword"]
	var sword_end: Vector2 = final["sword"]
	sword.position = Vector2(-10.0 * flip, -18.0)
	sword.rotation = -PI * 0.6 * flip
	var sword_top := Vector2(sword_end.x - 6.0 * flip, sword_end.y - 34.0)
	tween.tween_property(sword, "position", sword_top, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sword, "position", sword_end, 0.22).set_delay(0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(sword, "rotation", TAU * 2.0 * flip, 0.52).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Меч воткнулся: дрожит
	tween.tween_property(sword, "rotation", TAU * 2.0 * flip + 0.08, 0.05).set_delay(0.52)
	tween.tween_property(sword, "rotation", TAU * 2.0 * flip - 0.05, 0.06).set_delay(0.57)
	tween.tween_property(sword, "rotation", TAU * 2.0 * flip, 0.08).set_delay(0.63)
	# Череп: слетает с плеч, кувыркается высоко и падает точно на рукоять
	var skull: Sprite2D = sprites["skull"]
	var skull_end: Vector2 = final["skull"]
	skull.position = Vector2(4.0 * flip, -38.0)
	var skull_top := Vector2(skull_end.x + 4.0 * flip, skull_end.y - 40.0)
	tween.tween_property(skull, "position", skull_top, 0.4).set_delay(0.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(skull, "position", skull_end, 0.35).set_delay(0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(skull, "rotation", -TAU * flip, 0.85).set_trans(Tween.TRANS_SINE)
	# Насадился: чуть сплющивается и встаёт
	var base := skull.scale
	tween.tween_property(skull, "scale", base * Vector2(1.15, 0.85), 0.06).set_delay(0.85)
	tween.tween_property(skull, "scale", base, 0.12).set_delay(0.91) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): Sound.play("enemy_hit"))
