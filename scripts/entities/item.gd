extends Interactable
## Предмет: попадает в сумку. Название и иконка из data/items.json.

var item_id := ""


func configure(data: Dictionary) -> void:
	prompt = "Взять"
	super(data)
	item_id = data.get("id", "")
	var icon_path: String = GameState.get_item(item_id).get("icon", "")
	if icon_path != "":
		$Sprite.texture = load(icon_path)


func interact(_player: Player) -> void:
	GameState.add_item(item_id)
	GameState.show_message("Найдено: " + GameState.get_item(item_id).get("name", item_id))
	consume()
