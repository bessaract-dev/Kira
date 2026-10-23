extends Interactable
## Записка: при чтении открывается окно с текстом из data/notes.json.

var note_id := ""


func configure(data: Dictionary) -> void:
	prompt = "Прочитать"
	super(data)
	note_id = data.get("id", "")


func interact(_player: Player) -> void:
	GameState.collect_note(note_id)
	consume()
