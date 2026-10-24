extends Node
## Быстрая проверка, что уровни собираются и механики работают.
## Запуск: godot --headless --path . res://tests/smoke_test.tscn

var _failed := 0


func _ready() -> void:
	_test_upgrades()
	_test_chains()
	_test_touch_mouse()
	for level_id in GameState.LEVELS:
		await _test_level(level_id)
	await _test_animation()
	await _test_attacks()
	await _test_double_jump()
	await _test_hook()
	await _test_wall_jump()
	print("SMOKE ", "OK" if _failed == 0 else "FAILED: %d" % _failed)
	get_tree().quit(_failed)


func _check(condition: bool, what: String) -> void:
	if not condition:
		_failed += 1
		push_error("FAIL: " + what)
	else:
		print("  ok: ", what)


func _test_upgrades() -> void:
	GameState.new_game()
	GameState.add_shards(20)
	_check(GameState.buy_upgrade("vitality") and GameState.get_max_hp() == 4, "здоровье 4")
	_check(GameState.buy_upgrade("swift") and GameState.get_stat("move_speed") == 187.0, "скорость 187")
	_check(GameState.shards == 14, "осколков осталось 14")


func _test_chains() -> void:
	GameState.new_game()
	for id in ["chain_whip", "chain_throw", "chain_hook"]:
		GameState.add_item(id)
	_check(GameState.abilities.size() == 3, "три приёма цепей")
	GameState.add_item("letter_k")
	_check(not GameState.has_ability("whip"), "К забирает хлыст")
	GameState.add_item("letter_i")
	_check(not GameState.has_ability("throw"), "И забирает бросок")
	GameState.add_item("letter_r")
	_check(not GameState.has_ability("hook"), "Р забирает крюк")
	GameState.add_item("letter_a")
	_check(GameState.has_ability("free") and GameState.has_ability("wall_jump"), "А освобождает")
	_check("".join(GameState.get_letters()) == "КИРА", "имя КИРА")


## Смерть Киры перезагрузила бы сцену и прервала тест.
func _has_mouse(action: String) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			return true
	return false


func _test_touch_mouse() -> void:
	var was := GameState.touch_mode
	GameState.set_touch_mode(true)
	_check(not _has_mouse("attack") and not _has_mouse("throw"), "касание экрана не бьёт хлыстом и не бросает цепь")
	GameState.set_touch_mode(false)
	_check(_has_mouse("attack") and _has_mouse("throw"), "на ПК мышь снова атакует")
	GameState.set_touch_mode(was)


func _load_level(level_id: String) -> Node2D:
	GameState.current_level = level_id
	GameState.checkpoint = null
	var level: Node2D = load(GameState.LEVEL_SCENE).instantiate()
	add_child(level)
	level.player.died.disconnect(level._on_player_died)
	for i in 30:
		await get_tree().physics_frame
	return level


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _test_level(level_id: String) -> void:
	print(level_id)
	GameState.new_game()
	var level := await _load_level(level_id)
	var player: Player = level.player
	_check(player != null and player.is_on_floor(), "Кира стоит на полу")
	_check(level.get_node("Entities").get_child_count() > 10, "объекты расставлены")
	var start := player.global_position
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	_check(player.global_position.x > start.x + 30, "бег вправо")
	Input.action_press("jump")
	await _frames(10)
	Input.action_release("jump")
	_check(player.global_position.y < start.y - 30, "прыжок")
	level.queue_free()
	await get_tree().process_frame


func _test_animation() -> void:
	print("покадровая анимация")
	GameState.new_game()
	var level := await _load_level("level_01")
	var player: Player = level.player
	_check(player.has_node("Animated"), "кадры Киры подключены")
	var anim: AnimatedSprite2D = player.get_node("Animated")
	_check(anim.animation == "idle", "анимация покоя")
	Input.action_press("move_right")
	await _frames(10)
	_check(anim.animation == "run", "анимация бега")
	Input.action_release("move_right")
	Input.action_press("jump")
	await _frames(5)
	Input.action_release("jump")
	_check(anim.animation == "jump", "анимация прыжка")
	level.queue_free()
	await get_tree().process_frame


func _test_attacks() -> void:
	print("хлыст и бросок")
	GameState.new_game()
	GameState.add_item("chain_whip")
	GameState.add_item("chain_throw")
	var level := await _load_level("level_01")
	var player: Player = level.player
	var soul: Node2D = null
	for node in level.get_node("Entities").get_children():
		if node.scene_file_path.ends_with("enemy_soul.tscn"):
			soul = node
			break
	player.global_position = soul.global_position - Vector2(40, 0)
	await _frames(2)
	Input.action_press("attack")
	await _frames(4)
	Input.action_release("attack")
	await _frames(20)
	_check(not is_instance_valid(soul), "хлыст побеждает душу")
	Input.action_press("throw")
	await _frames(4)
	Input.action_release("throw")
	var bolts := level.get_children().filter(func(n): return n.name.begins_with("ChainBolt"))
	_check(bolts.size() == 1, "бросок выпускает цепь")
	level.queue_free()
	await get_tree().process_frame


func _test_hook() -> void:
	print("крюк")
	GameState.new_game()
	GameState.add_item("chain_hook")
	var level := await _load_level("level_01")
	var player: Player = level.player
	player.global_position = Vector2(65 * 32 + 16, 13 * 32)
	await _frames(10)
	Input.action_press("move_right")
	Input.action_press("hook")
	await _frames(2)
	Input.action_release("hook")
	await _frames(90)
	Input.action_release("move_right")
	_check(player.global_position.x > 74 * 32 and player.global_position.y <= 13 * 32 + 1, "перелёт пропасти на крюке")
	level.queue_free()
	await get_tree().process_frame


func _test_double_jump() -> void:
	print("двойной прыжок")
	GameState.new_game()
	var level := await _load_level("level_01")
	var player: Player = level.player
	Input.action_press("jump")
	await _frames(22)
	Input.action_release("jump")
	await _frames(2)
	_check(not player.is_on_floor() and player.velocity.y > -150.0, "Кира в верхней точке прыжка")
	Input.action_press("jump")
	await _frames(3)
	_check(player.velocity.y < -300.0, "второй прыжок в воздухе")
	Input.action_release("jump")
	await _frames(2)
	Input.action_press("jump")
	await _frames(3)
	Input.action_release("jump")
	_check(player.velocity.y > -300.0, "третьего прыжка нет")
	await _frames(60)
	level.queue_free()
	await _frames(2)


func _test_wall_jump() -> void:
	print("прыжки от стен")
	GameState.new_game()
	GameState.add_item("letter_a")
	var level := await _load_level("level_03")
	level.get_tree().call_group("chaser_group", "queue_free")
	var player: Player = level.player
	player.global_position = Vector2(36 * 32 + 16, 17 * 32)
	await _frames(10)
	# Как играет человек: подпрыгнуть, долететь до стены, оттолкнуться к другой стене и так далее.
	var direction := "move_right"
	Input.action_press(direction)
	Input.action_press("jump")
	await _frames(12)
	Input.action_release("jump")
	for i in 16:
		for f in 40:
			await get_tree().physics_frame
			if player.is_on_wall_only():
				break
		Input.action_release(direction)
		direction = "move_right" if direction == "move_left" else "move_left"
		Input.action_press(direction)
		Input.action_press("jump")
		await _frames(14)
		Input.action_release("jump")
		if player.global_position.y < 7 * 32:
			break
	Input.action_release(direction)
	Input.action_press("move_right")
	await _frames(60)
	Input.action_release("move_right")
	_check(player.global_position.x > 39 * 32, "выбралась из шахты прыжками от стен")
	level.queue_free()
	await get_tree().process_frame
