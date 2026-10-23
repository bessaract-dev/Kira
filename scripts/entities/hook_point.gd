extends Node2D
## Железное кольцо: за него цепляется цепь-крюк. Светится, когда до него можно дотянуться.

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("hook_point")


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var reachable := player != null and GameState.has_ability("hook") \
		and player.global_position.distance_to(global_position) < GameState.get_stat("hook_range") + 24.0
	_sprite.modulate = Color(1.6, 1.8, 2.2) if reachable else Color(0.8, 0.8, 0.9)
