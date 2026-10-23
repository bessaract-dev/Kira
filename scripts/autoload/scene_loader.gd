extends CanvasLayer
## Плавная смена сцен через затемнение (автозагрузка SceneLoader).

var _fade: ColorRect
var _busy := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.modulate.a = 0.0
	add_child(_fade)


func change_scene(path: String, fade_time := 0.6) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	await _tween_alpha(1.0, fade_time)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _tween_alpha(0.0, fade_time)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


## Затемнение без смены сцены (например, при возрождении у свечи).
func fade_out_in(callback: Callable, fade_time := 0.4) -> void:
	if _busy:
		return
	_busy = true
	await _tween_alpha(1.0, fade_time)
	callback.call()
	await _tween_alpha(0.0, fade_time)
	_busy = false


func _tween_alpha(target: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", target, time)
	await tween.finished
