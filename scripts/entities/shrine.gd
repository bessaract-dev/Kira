extends Interactable
## Свеча-святилище: сохраняет точку возрождения, лечит и открывает прокачку.


func configure(data: Dictionary) -> void:
	prompt = "Свеча: отдых и улучшения"
	super(data)


func interact(_player: Player) -> void:
	GameState.checkpoint = global_position
	GameState.heal_full()
	get_tree().call_group("hud", "open_upgrades")
