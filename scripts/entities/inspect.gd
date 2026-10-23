extends Interactable
## Осматриваемый объект: показывает мысль Киры.

var text := ""


func configure(data: Dictionary) -> void:
	super(data)
	text = data.get("text", "")


func interact(_player: Player) -> void:
	GameState.show_message(text)
