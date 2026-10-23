extends Control
## Главное меню.


func _ready() -> void:
	get_tree().paused = false
	%NewGameButton.pressed.connect(_on_new_game)
	%QuitButton.pressed.connect(get_tree().quit)
	# В браузере кнопка «Выход» не нужна.
	%QuitButton.visible = not OS.has_feature("web")
	%NewGameButton.grab_focus()
	var tween := create_tween().set_loops()
	tween.tween_property(%Title, "modulate:a", 0.75, 2.0)
	tween.tween_property(%Title, "modulate:a", 1.0, 2.0)


func _on_new_game() -> void:
	GameState.new_game()
	GameState.go_to("level_01")
