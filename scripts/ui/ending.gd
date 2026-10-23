extends Control
## Финальная сцена: текст медленно проявляется, потом кнопка в меню.


func _ready() -> void:
	%Text.modulate.a = 0.0
	%MenuButton.modulate.a = 0.0
	%MenuButton.disabled = true
	%MenuButton.pressed.connect(GameState.go_to.bind("menu"))
	var tween := create_tween()
	tween.tween_interval(0.5)
	tween.tween_property(%Text, "modulate:a", 1.0, 3.0)
	tween.tween_interval(1.5)
	tween.tween_property(%MenuButton, "modulate:a", 1.0, 1.0)
	tween.tween_callback(func(): %MenuButton.disabled = false; %MenuButton.grab_focus())
