extends CanvasLayer

var busy: bool = false
var veil: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 1000

	veil = ColorRect.new()
	veil.color = Color(0, 0, 0, 0)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP

	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.hide()


func go_to_scene(scene_path: String, delay: float = 1.05) -> void:
	if busy:
		return

	if not ResourceLoader.exists(scene_path, "PackedScene"):
		push_error("StageTransition: scene not found: " + scene_path)
		return

	busy = true

	var tree := get_tree()
	var was_paused := tree.paused

	tree.paused = true
	veil.show()

	await tree.create_timer(delay, true).timeout
	await _fade_to(1.0, 0.3)

	var result := tree.change_scene_to_file(scene_path)

	if result != OK:
		push_error("StageTransition: " + error_string(result))
		await _fade_to(0.0, 0.2)
		veil.hide()
		tree.paused = was_paused
		busy = false
		return

	await tree.scene_changed

	var camera := get_viewport().get_camera_2d()
	if camera != null:
		camera.force_update_scroll()

	await _fade_to(0.0, 0.25)

	veil.hide()
	tree.paused = was_paused
	busy = false


func _fade_to(alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(veil, "color:a", alpha, duration)
	await tween.finished
