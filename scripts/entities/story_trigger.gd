extends Area2D
## Невидимая зона: когда Кира входит в неё первый раз, показывается мысль.

var text := ""
var persist_key := ""


func configure(data: Dictionary) -> void:
	text = data.get("text", "")


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		GameState.show_message(text)
		if persist_key != "":
			GameState.mark_picked(persist_key)
		queue_free()
