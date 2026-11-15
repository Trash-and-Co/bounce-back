extends Sprite2D

@export var hover_height: float = 3.0
@export_range(0.2, 10.0, 0.1) var hover_period: float = 2.0
@export var letter_font: Font

@export_multiline var message: String = "Hey,\n\nI'm locked up past the grass plateaus. They broke the key and hid the pieces.\n\nPlease find them and get me out. I'll explain everything when I'm home.\n\n- Bob"

@onready var area: Area2D = $Area2D
@onready var dialogue: PanelContainer = $CanvasLayer/Dialogue
@onready var text_label: Label = $CanvasLayer/Dialogue/VBoxContainer/Text
@onready var continue_button: Button = $CanvasLayer/Dialogue/VBoxContainer/Continue

var elapsed: float = 0.0
var original_offset_y: float
var collected: bool = false
var shade: ColorRect


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	original_offset_y = offset.y

	$CanvasLayer.layer = 20
	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS

	shade = ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	$CanvasLayer.add_child(shade)
	$CanvasLayer.move_child(shade, 0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	shade.hide()
	dialogue.hide()

	var ui_theme := Theme.new()
	ui_theme.default_font_size = 20

	if letter_font != null:
		ui_theme.default_font = letter_font

	dialogue.theme = ui_theme

	var margins := StyleBoxEmpty.new()
	margins.content_margin_left = 36
	margins.content_margin_right = 36
	margins.content_margin_top = 40
	margins.content_margin_bottom = 28
	dialogue.add_theme_stylebox_override("panel", margins)

	dialogue.draw.connect(_draw_paper)
	dialogue.resized.connect(dialogue.queue_redraw)

	var box: VBoxContainer = $CanvasLayer/Dialogue/VBoxContainer
	box.add_theme_constant_override("separation", 20)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	box.move_child(scroll, 0)

	text_label.reparent(scroll)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_color_override("font_color", Color("342c25"))
	text_label.add_theme_constant_override("line_spacing", 4)
	text_label.text = message

	continue_button.text = "Put away"
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	continue_button.add_theme_font_size_override("font_size", 18)

	for state in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color"
	]:
		continue_button.add_theme_color_override(state, Color("342c25"))

	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color(0, 0, 0, 0)
	button_style.border_color = Color("736047")
	button_style.border_width_bottom = 1
	button_style.content_margin_left = 8
	button_style.content_margin_right = 8
	button_style.content_margin_top = 6
	button_style.content_margin_bottom = 6

	continue_button.add_theme_stylebox_override("normal", button_style)

	var highlighted := button_style.duplicate() as StyleBoxFlat
	highlighted.bg_color = Color("dfcda7")

	for state in ["hover", "pressed", "focus"]:
		continue_button.add_theme_stylebox_override(state, highlighted)

	_layout_letter()

	get_viewport().size_changed.connect(_layout_letter)
	area.body_entered.connect(_on_body_entered)
	continue_button.pressed.connect(_close_letter)


func _layout_letter() -> void:
	var screen := get_viewport_rect().size

	dialogue.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	dialogue.size = Vector2(
		minf(620, screen.x - 48),
		minf(480, screen.y - 48)
	)
	dialogue.position = ((screen - dialogue.size) * 0.5).round()


func _draw_paper() -> void:
	var w := dialogue.size.x
	var h := dialogue.size.y

	var paper := PackedVector2Array([
		Vector2.ZERO,
		Vector2(w - 26, 0),
		Vector2(w, 26),
		Vector2(w, h),
		Vector2(0, h)
	])

	var shadow := PackedVector2Array()

	for point in paper:
		shadow.append(point + Vector2(6, 6))

	dialogue.draw_colored_polygon(shadow, Color(0, 0, 0, 0.3))
	dialogue.draw_colored_polygon(paper, Color("efdfbb"))

	var edge := paper.duplicate()
	edge.append(paper[0])
	dialogue.draw_polyline(edge, Color("796348"), 2.0)

	var fold := PackedVector2Array([
		Vector2(w - 26, 0),
		Vector2(w - 26, 26),
		Vector2(w, 26)
	])

	dialogue.draw_colored_polygon(fold, Color("cbb58d"))
	dialogue.draw_polyline(fold, Color("796348"), 2.0)


func _process(delta: float) -> void:
	if collected:
		return

	elapsed += delta

	offset.y = roundf(
		original_offset_y
		+ sin(elapsed * TAU / hover_period) * hover_height
	)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return

	collected = true
	self_modulate.a = 0.0
	area.set_deferred("monitoring", false)

	text_label.text = message
	shade.show()
	dialogue.show()

	get_tree().paused = true
	continue_button.grab_focus.call_deferred()


func _close_letter() -> void:
	dialogue.hide()
	shade.hide()
	get_tree().paused = false
