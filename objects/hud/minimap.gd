extends Panel

@export var map_size: Vector2i = Vector2i(220, 136)
@export_range(0.05, 0.5, 0.01) var map_zoom: float = 0.12
@export var background_texture: Texture2D

@onready var display: TextureRect = $MapDisplay
@onready var map_viewport: SubViewport = $MapViewport
@onready var map_camera: Camera2D = $MapViewport/MapCamera

var player: Node2D
var player_dot: ColorRect
var backdrop: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("91bdd1")
	frame.border_color = Color("171b20")
	frame.set_border_width_all(2)
	add_theme_stylebox_override("panel", frame)

	backdrop = TextureRect.new()
	backdrop.name = "MapBackground"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(backdrop)

	backdrop.texture = background_texture

	display.material = null
	display.use_parent_material = false
	display.self_modulate = Color.WHITE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.z_index = 1

	map_viewport.disable_3d = true
	map_viewport.gui_disable_input = true
	map_viewport.transparent_bg = true
	map_viewport.canvas_cull_mask = 1
	map_viewport.world_2d = get_viewport().world_2d
	map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	display.texture = map_viewport.get_texture()

	map_camera.enabled = true
	map_camera.position_smoothing_enabled = false
	map_camera.offset = Vector2.ZERO
	map_camera.make_current()

	player_dot = get_node_or_null("PlayerDot") as ColorRect

	if player_dot == null:
		player_dot = ColorRect.new()
		player_dot.name = "PlayerDot"
		add_child(player_dot)

	player_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_dot.color = Color.WHITE
	player_dot.size = Vector2(4, 4)
	player_dot.z_index = 2

	var outline := ColorRect.new()
	outline.color = Color("171b20")
	outline.position = Vector2(-1, -1)
	outline.size = Vector2(6, 6)
	outline.show_behind_parent = true
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_dot.add_child(outline)

	_place_minimap()
	get_viewport().size_changed.connect(_place_minimap)


func _place_minimap() -> void:
	size = Vector2(map_size)
	position = Vector2(
		16,
		get_viewport_rect().size.y - size.y - 16
	)

	display.position = Vector2(3, 3)
	display.size = size - Vector2(6, 6)

	backdrop.position = display.position
	backdrop.size = display.size

	map_viewport.size = Vector2i(display.size)

	player_dot.position = (
		display.position
		+ display.size * 0.5
		- player_dot.size * 0.5
	)


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if is_instance_valid(player):
		map_camera.global_position = player.global_position
		map_camera.zoom = Vector2.ONE * map_zoom
