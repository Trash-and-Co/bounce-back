extends Sprite2D

signal picked_up(key_id: StringName)

@export var key_id: StringName = &"castle_key"
@export var hover_height: float = 3.0
@export_file("*.tscn") var next_scene: String = ""
@export var transition_delay: float = 1.05
@export_range(0.2, 10.0, 0.1) var hover_period: float = 2.0

@onready var area: Area2D = $Area2D

var elapsed: float = 0.0
var original_offset_y: float
var collected: bool = false


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	original_offset_y = offset.y

	if get_tree().current_scene.get_meta(key_id, false):
		queue_free()
		return

	area.body_entered.connect(_on_body_entered)


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
	process_mode = Node.PROCESS_MODE_ALWAYS
	area.set_deferred("monitoring", false)

	get_tree().current_scene.set_meta(key_id, true)

	_spawn_sparkles()
	picked_up.emit(key_id)

	self_modulate = Color(2, 2, 2, 1)

	var tween := create_tween().set_parallel(true)

	tween.tween_property(
		self, "self_modulate", Color.WHITE, 0.18
	)

	tween.tween_property(
		self, "position:y", position.y - 32.0, 0.8
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self, "modulate:a", 0.0, 0.6
	).set_delay(0.2)

	tween.finished.connect(queue_free)
	if not next_scene.is_empty():
		StageTransition.go_to_scene(next_scene, transition_delay)

func _spawn_sparkles() -> void:
	var particles := CPUParticles2D.new()
	particles.process_mode = Node.PROCESS_MODE_ALWAYS
	particles.emitting = false
	particles.amount = 10
	particles.lifetime = 0.9
	particles.one_shot = true
	particles.explosiveness = 1.0

	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 35.0
	particles.initial_velocity_max = 85.0
	particles.gravity = Vector2(0, 100)

	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.z_index = 10
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var colors := Gradient.new()
	colors.set_color(0, Color("ffe28a"))
	colors.set_color(1, Color(1.0, 0.75, 0.25, 0.0))
	particles.color_ramp = colors

	get_tree().current_scene.add_child(particles)
	particles.global_position = to_global(offset)

	particles.finished.connect(particles.queue_free)
	particles.emitting = true
