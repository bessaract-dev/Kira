extends Interactable
## Голубое пламя: сохраняет точку возрождения, лечит и открывает прокачку.


func configure(data: Dictionary) -> void:
	prompt = "Голубое пламя: отдых и улучшения"
	super(data)


func interact(_player: Player) -> void:
	Sound.play("shrine")
	GameState.checkpoint = global_position
	GameState.heal_full()
	get_tree().call_group("hud", "open_upgrades")
