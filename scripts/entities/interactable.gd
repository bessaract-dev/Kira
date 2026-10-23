class_name Interactable
extends Area2D
## Основа для всего, с чем можно взаимодействовать кнопкой «Действие».
## Наследники переопределяют interact(). Уровень вызывает configure()
## с данными из JSON уровня перед добавлением на сцену.

@export var prompt := "Осмотреть"
## Если не пусто: после consume() вещь не появится снова (даже после смерти).
var persist_key := ""


func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	monitorable = true


func configure(data: Dictionary) -> void:
	prompt = data.get("prompt", prompt)


func is_available() -> bool:
	return true


func get_prompt() -> String:
	return prompt


func interact(_player: Player) -> void:
	pass


## Убрать вещь с уровня навсегда.
func consume() -> void:
	if persist_key != "":
		GameState.mark_picked(persist_key)
	queue_free()
