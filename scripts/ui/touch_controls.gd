extends Control
## Экранные кнопки для планшета. Каждая кнопка (TouchScreenButton) сама
## нажимает своё действие из Input Map, поэтому героиня не отличает
## сенсор от клавиатуры. На ПК кнопки включаются клавишей F2.


func _ready() -> void:
	GameState.touch_mode_changed.connect(_on_touch_mode_changed)
	GameState.upgrade_bought.connect(_on_upgrade_bought)
	_refresh()
	set_active(true)


## HUD прячет кнопки, когда открыто меню или записка.
func set_active(active: bool) -> void:
	visible = active and GameState.touch_mode


func _on_touch_mode_changed(_enabled: bool) -> void:
	set_active(true)


func _on_upgrade_bought(_id: String) -> void:
	_refresh()


func _refresh() -> void:
	# Кнопка рывка появляется только после покупки улучшения.
	%Dash.visible = GameState.get_stat("dash_charges") > 0
