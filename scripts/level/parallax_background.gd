extends CanvasLayer
## Фон с параллаксом. Каждый дочерний Sprite2D это слой картинки во всю высоту экрана,
## который бесконечно повторяется по горизонтали. В свойстве слоя "factor"
## (Metadata) указано, как быстро он едет за камерой: 0 стоит на месте, 1 как мир.
## Необязательное "drift" сдвигает слой само по себе (пикселей в секунду), так плывёт туман.

var _time := 0.0


func _ready() -> void:
	layer = -10
	for sprite: Sprite2D in get_children():
		sprite.centered = false
		sprite.region_enabled = true
		sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _process(delta: float) -> void:
	_time += delta
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var screen := get_viewport().get_visible_rect().size
	var center_x := camera.get_screen_center_position().x * camera.zoom.x
	for sprite: Sprite2D in get_children():
		var texture_size := sprite.texture.get_size()
		var fit := screen.y / texture_size.y
		var factor: float = sprite.get_meta("factor", 0.5)
		var drift: float = sprite.get_meta("drift", 0.0)
		sprite.scale = Vector2(fit, fit)
		sprite.region_rect = Rect2((center_x * factor + _time * drift) / fit, 0.0, screen.x / fit, texture_size.y)
