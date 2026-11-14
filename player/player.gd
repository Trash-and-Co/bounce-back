extends CharacterBody2D

const DRAG_DEAD_ZONE: float = 12.0
const FULL_PULL_DISTANCE: float = 200.0
const MIN_PULL_STRENGTH: float = 0.07
const DETACH_DISTANCE: float = 2.0
const PREVIEW_STEPS: int = 18
const FIRST_DOT_DISTANCE: float = 26.0
const DOT_SPACING: float = 12.0
const CLICK_PREVIEW_DOTS: int = 3
const DRAG_PREVIEW_DOTS: int = 8

@export var launch_power: float = 6.0
@export var max_drag: float = 120.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var attached: bool = false
var death_in_progress: bool = false
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var pullback_started: bool = false
var surface_normal: Vector2 = Vector2.UP
var detach_pending: bool = false

var trajectory := PackedVector2Array()


func _ready() -> void:
	add_to_group("player")
	sprite.play("idle")


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		var mouse: Vector2 = get_canvas_transform().affine_inverse() * event.position
		pullback_started = pullback_started or drag_start.distance_to(mouse) > DRAG_DEAD_ZONE
		return

	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse: Vector2 = get_canvas_transform().affine_inverse() * event.position
	if event.pressed:
		if attached and not death_in_progress:
			dragging = true
			drag_start = mouse
			pullback_started = false
			trajectory.clear()
		return

	if not dragging:
		return

	dragging = false
	queue_redraw()
	if event.canceled or not attached or death_in_progress:
		return

	var shot := _shot_velocity(mouse)
	if shot.is_zero_approx():
		return

	velocity = shot
	attached = false
	detach_pending = true
	sprite.play("idle")

	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0


func _shot_velocity(mouse: Vector2) -> Vector2:
	var pull := drag_start - mouse
	var distance := pull.length()
	var max_speed := max_drag * launch_power

	if distance > DRAG_DEAD_ZONE:
		var fraction := clampf(inverse_lerp(DRAG_DEAD_ZONE, FULL_PULL_DISTANCE, distance), 0.0, 1.0)
		var strength := lerpf(MIN_PULL_STRENGTH, 1.0, pow(fraction, 1.25))
		return pull / distance * max_speed * strength

	if pullback_started or global_position.distance_to(mouse) <= DRAG_DEAD_ZONE:
		return Vector2.ZERO

	return global_position.direction_to(mouse) * max_speed


func _physics_process(delta: float) -> void:
	if detach_pending:
		move_and_collide(surface_normal * DETACH_DISTANCE)
		detach_pending = false

	if not attached:
		velocity += get_gravity() * delta
		var collision := move_and_collide(velocity * delta)

		if collision:
			velocity = Vector2.ZERO
			attached = true
			surface_normal = collision.get_normal()

			if absf(surface_normal.x) > 0.7:
				sprite.play("wall_stick")
				sprite.flip_h = surface_normal.x < 0.0
			else:
				sprite.play("idle")

	if dragging:
		var mouse := get_global_mouse_position()
		var is_pullback := pullback_started or drag_start.distance_to(mouse) > DRAG_DEAD_ZONE
		var dot_limit := DRAG_PREVIEW_DOTS if is_pullback else CLICK_PREVIEW_DOTS
		_update_trajectory(_shot_velocity(mouse), delta, dot_limit)

	queue_redraw()


func _update_trajectory(shot: Vector2, delta: float, dot_limit: int) -> void:
	trajectory.clear()
	if shot.is_zero_approx():
		return

	var start := global_transform
	var detach := surface_normal * DETACH_DISTANCE
	if not test_move(start, detach):
		start.origin += detach

	var gravity := get_gravity()
	var distance_to_dot := FIRST_DOT_DISTANCE

	for step in range(PREVIEW_STEPS):
		shot += gravity * delta
		var motion := shot * delta
		if test_move(start, motion):
			break

		var segment_length := motion.length()
		while distance_to_dot <= segment_length:
			var point := start.origin + motion * (distance_to_dot / segment_length)
			trajectory.append(to_local(point))
			if trajectory.size() == dot_limit:
				return
			distance_to_dot += DOT_SPACING

		distance_to_dot -= segment_length
		start.origin += motion


func _draw() -> void:
	if not dragging:
		return

	for index in range(trajectory.size()):
		var fade := float(index) / maxf(1.0, float(trajectory.size() - 1))
		var radius := lerpf(3.2, 1.7, fade)
		var color := Color(1.0, 0.89, 0.62, lerpf(0.95, 0.25, fade))
		var outline := Color(0.12, 0.09, 0.06, color.a * 0.65)
		draw_circle(trajectory[index], radius + 1.0, outline, true, -1.0, true)
		draw_circle(trajectory[index], radius, color, true, -1.0, true)


func claim_death() -> bool:
	if death_in_progress:
		return false

	death_in_progress = true
	dragging = false
	queue_redraw()
	return true
