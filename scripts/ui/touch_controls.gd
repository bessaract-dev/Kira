extends Control
## Экранные кнопки для планшета. Каждая кнопка (TouchScreenButton) сама
## нажимает своё действие из Input Map, поэтому Кира не отличает
## сенсор от клавиатуры. На ПК кнопки включаются клавишей F2.
## Кнопки цепей видны, только пока у Киры есть этот приём.

const ABILITY_BUTTONS := {"Whip": "whip", "Throw": "throw", "Hook": "hook"}


func _ready() -> void:
	GameState.touch_mode_changed.connect(_on_touch_mode_changed)
	GameState.abilities_changed.connect(_refresh)
	_refresh()
	set_active(true)


## HUD прячет кнопки, когда открыто меню или записка.
func set_active(active: bool) -> void:
	visible = active and GameState.touch_mode


func _on_touch_mode_changed(_enabled: bool) -> void:
	set_active(true)


func _refresh() -> void:
	for button_name in ABILITY_BUTTONS:
		get_node("%" + button_name).visible = GameState.has_ability(ABILITY_BUTTONS[button_name])
