extends Interactable
## Выход с уровня (решётка склепа, саркофаг с телом). Может требовать предметы.

const LOOKS := {
	"gate": preload("res://assets/textures/entities/door.png"),
	"body": preload("res://assets/textures/entities/altar.png"),
}

var target := ""
var requires: Array = []
var locked_text := "Закрыто."


func configure(data: Dictionary) -> void:
	prompt = "Войти"
	super(data)
	target = data.get("target", "")
	requires = data.get("requires", [])
	locked_text = data.get("locked", locked_text)
	var look: String = data.get("look", "gate")
	if LOOKS.has(look):
		$Sprite.texture = LOOKS[look]
		$Sprite.offset.y = -LOOKS[look].get_height() / 2.0


func interact(player: Player) -> void:
	if not GameState.has_items(requires):
		GameState.show_message(locked_text)
		return
	player.input_enabled = false
	GameState.go_to(target)
