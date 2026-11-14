extends TextureButton

@export var target_label: Label
@export var platform_layer: TileMapLayer


func _ready() -> void:
	toggle_mode = true
	set_pressed_no_signal(false)

	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	shortcut = null

	$TouchArea.body_entered.connect(_on_body_entered)
	_update_text()
	_update_platform()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	set_pressed_no_signal(not button_pressed)

	$ToggleSound.pitch_scale = randf_range(0.9, 1.1)
	$ToggleSound.play()

	_update_text()
	_update_platform()


func _update_text() -> void:
	if target_label:
		target_label.text = "Switch: ON" if button_pressed else "Switch: OFF"


func _update_platform() -> void:
	if platform_layer:
		platform_layer.set_deferred("enabled", button_pressed)
