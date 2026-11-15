extends Panel

@export var map_size: Vector2i = Vector2i(220, 136)
@export_range(0.05, 0.5, 0.01) var map_zoom: float = 0.16
@export var world_background: CanvasItem

@onready var display: TextureRect = $MapDisplay
@onready var map_viewport: SubViewport = $MapViewport
@onready var map_camera: Camera2D = $MapViewport/MapCamera

var player: Node2D
var player_dot: ColorRect

const MAP_SHADER := """
shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec2 pixel = TEXTURE_PIXEL_SIZE;

	float solid = step(0.1, texture(TEXTURE, UV).a);
	float left = step(0.1, texture(TEXTURE, UV - vec2(pixel.x, 0.0)).a);
	float right = step(0.1, texture(TEXTURE, UV + vec2(pixel.x, 0.0)).a);
	float above = step(0.1, texture(TEXTURE, UV - vec2(0.0, pixel.y)).a);
	float below = step(0.1, texture(TEXTURE, UV + vec2(0.0, pixel.y)).a);

	float neighbors = min(min(left, right), min(above, below));
	float edge = solid * (1.0 - neighbors);

	vec3 color = mix(
		vec3(0.07, 0.08, 0.09),
		vec3(0.32, 0.33, 0.30),
		solid
	);

	color = mix(color, vec3(0.68, 0.70, 0.61), edge);
	COLOR = vec4(color, 1.0);
}
"""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("151719")
	frame.border_color = Color("0b0d0e")
	frame.set_border_width_all(2)
	add_theme_stylebox_override("panel", frame)

	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE

	var shader := Shader.new()
	shader.code = MAP_SHADER

	var map_material := ShaderMaterial.new()
	map_material.shader = shader
	display.material = map_material

	map_viewport.disable_3d = true
	map_viewport.gui_disable_input = true
	map_viewport.transparent_bg = true
	map_viewport.canvas_cull_mask = 1
	map_viewport.world_2d = get_viewport().world_2d
	map_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	display.texture = map_viewport.get_texture()

	if is_instance_valid(world_background):
		get_viewport().canvas_cull_mask |= 2
		world_background.visibility_layer = 2

	map_camera.enabled = true
	map_camera.position_smoothing_enabled = false
	map_camera.make_current()

	player_dot = get_node_or_null("PlayerDot") as ColorRect

	if player_dot == null:
		player_dot = ColorRect.new()
		player_dot.name = "PlayerDot"
		add_child(player_dot)

	player_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_dot.color = Color("edffc5")
	player_dot.size = Vector2(6, 6)
	player_dot.z_index = 2

	var outline := ColorRect.new()
	outline.color = Color("0b0d0e")
	outline.position = Vector2(-2, -2)
	outline.size = Vector2(10, 10)
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
