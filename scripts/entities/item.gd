extends Interactable
## Предмет: попадает в сумку и может дать или забрать способности цепей.
## Описание берётся из data/items.json. Буквы имени рисуются надписью вместо картинки.

var item_id := ""


func configure(data: Dictionary) -> void:
	prompt = "Взять"
	super(data)
	item_id = data.get("id", "")
	var item := GameState.get_item(item_id)
	var glyph: String = item.get("glyph", "")
	if glyph != "":
		prompt = "Вспомнить букву"
		$Sprite.visible = false
		$Glyph.visible = true
		$Glyph.text = glyph
	elif item.has("icon"):
		$Sprite.texture = load(item["icon"])


func interact(_player: Player) -> void:
	GameState.add_item(item_id)
	var item := GameState.get_item(item_id)
	GameState.show_message(item.get("description", item.get("name", item_id)))
	consume()
