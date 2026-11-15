extends CanvasLayer

@onready var overlay: ColorRect = $ColorRect
var fade_tween: Tween

func _ready() -> void:
	overlay.modulate.a = 1.0
	get_tree().scene_changed.connect(_on_scene_changed)

	# Also reveal the first scene when the game launches.
	await get_tree().process_frame
	if fade_tween == null:
		fade_from_black()


func _on_scene_changed() -> void:
	overlay.modulate.a = 1.0
	fade_from_black()


func fade_to_black(duration: float = 0.5) -> void:
	await _fade_to(1.0, duration)


func fade_from_black(duration: float = 0.5) -> void:
	await _fade_to(0.0, duration)


func _fade_to(alpha: float, duration: float) -> void:
	if fade_tween != null:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(overlay, "modulate:a", alpha, duration)
	await fade_tween.finished
