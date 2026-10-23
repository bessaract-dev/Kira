extends Node
## Быстрая проверка, что уровни собираются и героиня двигается.
## Запуск: godot --headless --path . res://tests/smoke_test.tscn

var _failed := 0


func _ready() -> void:
	await _test_upgrades()
	for level_id in GameState.LEVELS:
		await _test_level(level_id)
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
	_check(GameState.buy_upgrade("double_jump"), "покупка двойного прыжка")
	_check(GameState.get_stat("extra_jumps") == 1.0, "extra_jumps = 1")
	_check(not GameState.buy_upgrade("double_jump"), "второй раз купить нельзя")
	_check(GameState.buy_upgrade("vitality") and GameState.get_max_hp() == 4, "здоровье 4")
	_check(GameState.shards == 12, "осколков осталось 12")
	GameState.new_game()
	await get_tree().process_frame


func _test_level(level_id: String) -> void:
	print(level_id)
	GameState.current_level = level_id
	GameState.checkpoint = null
	var level: Node2D = load(GameState.LEVEL_SCENE).instantiate()
	add_child(level)
	await get_tree().physics_frame
	var player: Player = level.player
	_check(player != null, "героиня создана")
	_check(level.get_node("Entities").get_child_count() > 5, "объекты расставлены")
	for i in 30:
		await get_tree().physics_frame
	_check(player.is_on_floor(), "героиня стоит на полу")
	var start := player.global_position
	Input.action_press("move_right")
	for i in 30:
		await get_tree().physics_frame
	Input.action_release("move_right")
	_check(player.global_position.x > start.x + 40, "бег вправо")
	Input.action_press("jump")
	for i in 10:
		await get_tree().physics_frame
	Input.action_release("jump")
	_check(player.global_position.y < start.y - 30, "прыжок")
	level.queue_free()
	await get_tree().process_frame
