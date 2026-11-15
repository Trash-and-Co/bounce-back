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
const WALL_CONTACT_DISTANCE: float = 3.0
const CEILING_STRETCH: float = 1.38
const IDLE_BASE_OFFSET: float = 7.0

const MAX_HITS: int = 3
const IMPACT_TIME: float = 0.14
const HOLD_TIME: float = 1.0

@export var launch_power: float = 6.0
@export var max_drag: float = 120.0
@export var wall_slide_speed: float = 38.0
@export var wall_slide_acceleration: float = 220.0
@export var max_wall_slide_speed: float = 420.0
@export_range(0.1, 5.0, 0.1) var ceiling_hang_time: float = 2.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sprite_rest_y: float = sprite.position.y
@onready var sprite_rest_scale: Vector2 = sprite.scale
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var jump_sfx: AudioStreamPlayer2D = $JumpSFX
@onready var drop_sfx: AudioStreamPlayer2D = $DropSFX

var attached: bool = false
var death_in_progress: bool = false
var dragging: bool = false
var wall_slide_elapsed: float = 0.0
var drag_start: Vector2 = Vector2.ZERO
var pullback_started: bool = false
var surface_normal: Vector2 = Vector2.UP
var detach_pending: bool = false
var ceiling_elapsed: float = 0.0

var trajectory := PackedVector2Array()
var trajectory_overlay := Node2D.new()


func _ready() -> void:
	add_to_group("player")
	sprite.play("idle")

	trajectory_overlay.z_as_relative = false
	trajectory_overlay.z_index = 100
	add_child(trajectory_overlay)
	trajectory_overlay.draw.connect(_draw_trajectory)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and dragging:
		var motion_position: Vector2 = get_canvas_transform().affine_inverse() * event.position
		pullback_started = pullback_started or drag_start.distance_to(motion_position) > DRAG_DEAD_ZONE
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
	trajectory_overlay.queue_redraw()
	if event.canceled or not attached or death_in_progress:
		return

	var shot := _shot_velocity(mouse)
	if shot.is_zero_approx():
		return

	velocity = shot
	attached = false
	detach_pending = true

	drop_sfx.stop()
	jump_sfx.pitch_scale = randf_range(0.95, 1.05)
	jump_sfx.play()

	sprite.play("idle")
	_update_sprite_pose()

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

	if not attached or not _is_wall(surface_normal):
		wall_slide_elapsed = 0.0

	if attached:
		if not death_in_progress:
			if _is_wall(surface_normal):
				_slide_down_wall(delta)
			elif _is_ceiling(surface_normal):
				_hang_from_ceiling(delta)
	else:
		velocity += get_gravity() * delta
		var collision := move_and_collide(velocity * delta)
		if collision:
			_attach_to_surface(collision.get_normal())

	_update_sprite_pose()

	if dragging:
		var mouse := get_global_mouse_position()
		var is_pullback := pullback_started or drag_start.distance_to(mouse) > DRAG_DEAD_ZONE
		var dot_limit := DRAG_PREVIEW_DOTS if is_pullback else CLICK_PREVIEW_DOTS
		_update_trajectory(_shot_velocity(mouse), delta, dot_limit)

	trajectory_overlay.queue_redraw()


func _is_wall(normal: Vector2) -> bool:
	return absf(normal.x) > 0.7


func _is_ceiling(normal: Vector2) -> bool:
	return normal.y > 0.7 and not _is_wall(normal)


func _attach_to_surface(normal: Vector2) -> void:
	if not attached or not _is_wall(surface_normal) or surface_normal.dot(normal) < 0.95:
		wall_slide_elapsed = 0.0

	velocity = Vector2.ZERO
	attached = true
	surface_normal = normal
	ceiling_elapsed = 0.0

	if _is_wall(normal):
		sprite.play("wall_stick")
		sprite.flip_h = normal.x < 0.0
	else:
		sprite.play("idle")


func _hang_from_ceiling(delta: float) -> void:
	ceiling_elapsed += delta
	if ceiling_elapsed >= ceiling_hang_time:
		attached = false
		dragging = false
		velocity = Vector2.ZERO

		drop_sfx.pitch_scale = randf_range(0.95, 1.05)
		drop_sfx.play()


func _update_sprite_pose() -> void:
	var on_ceiling := attached and _is_ceiling(surface_normal)
	sprite.flip_v = on_ceiling
	if not on_ceiling:
		sprite.scale = sprite_rest_scale
		sprite.position.y = sprite_rest_y
		return

	var progress := smoothstep(0.0, ceiling_hang_time, ceiling_elapsed)
	var ceiling_y := 2.0 * collision_shape.position.y - sprite_rest_y
	sprite.scale = sprite_rest_scale * Vector2(
		lerpf(1.0, 0.92, progress),
		lerpf(1.0, CEILING_STRETCH, progress)
	)
	# Keep the flat edge of the idle sprite anchored while it stretches down.
	sprite.position.y = ceiling_y + IDLE_BASE_OFFSET * (sprite.scale.y - sprite_rest_scale.y)


func _slide_down_wall(delta: float) -> void:
	wall_slide_elapsed += delta

	var speed := minf(
		wall_slide_speed + wall_slide_acceleration * wall_slide_elapsed,
		maxf(wall_slide_speed, max_wall_slide_speed)
	)

	var slide_velocity := Vector2.DOWN.slide(surface_normal).normalized() * speed
	var collision := move_and_collide(slide_velocity * delta)

	if collision:
		_attach_to_surface(collision.get_normal())
		return

	if not test_move(global_transform, -surface_normal * WALL_CONTACT_DISTANCE):
		attached = false
		dragging = false
		velocity = slide_velocity
		surface_normal = Vector2.UP
		sprite.play("idle")

		drop_sfx.pitch_scale = randf_range(0.95, 1.05)
		drop_sfx.play()


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
	var aim_direction := shot.normalized()

	for step in range(PREVIEW_STEPS):
		shot += gravity * delta
		var motion := shot * delta

		var segment_length := motion.length()
		while distance_to_dot <= segment_length:
			var point := start.origin + motion * (distance_to_dot / segment_length)
			trajectory.append(to_local(point))
			if trajectory.size() == dot_limit:
				return
			distance_to_dot += DOT_SPACING

		distance_to_dot -= segment_length
		start.origin += motion

	if trajectory.is_empty():
		trajectory.append(to_local(global_position + aim_direction * FIRST_DOT_DISTANCE))


func _draw_trajectory() -> void:
	if not dragging:
		return

	for index in range(trajectory.size()):
		var fade := float(index) / maxf(1.0, float(trajectory.size() - 1))
		var radius := lerpf(3.2, 1.7, fade)
		var color := Color(1.0, 0.89, 0.62, lerpf(0.95, 0.25, fade))
		var outline := Color(0.12, 0.09, 0.06, color.a * 0.65)
		trajectory_overlay.draw_circle(trajectory[index], radius + 1.0, outline, true, -1.0, true)
		trajectory_overlay.draw_circle(trajectory[index], radius, color, true, -1.0, true)


func claim_death() -> bool:
	if death_in_progress:
		return false

	death_in_progress = true
	dragging = false
	trajectory_overlay.queue_redraw()
	return true


func take_damage(on_survived: Callable = Callable()) -> bool:
	var level := get_tree().current_scene
	if level == null or level.get_meta("restart_pending", false):
		return false

	if not claim_death():
		return false

	set_physics_process(false)
	_resolve_damage.call_deferred(level, on_survived)
	return true


func _resolve_damage(level: Node, on_survived: Callable) -> void:
	if get_tree().current_scene != level:
		return

	velocity = Vector2.ZERO
	sprite.flip_h = false
	sprite.flip_v = false
	sprite.play("idle")
	sprite.frame = 1
	sprite.pause()

	var squash := create_tween()
	squash.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash.tween_property(sprite, "scale", Vector2(5.0, 2.0), IMPACT_TIME)
	await squash.finished

	sprite.hide()
	await get_tree().create_timer(HOLD_TIME, false).timeout

	if get_tree().current_scene != level:
		return

	var hits := int(level.get_meta("damage_taken", 0)) + 1
	var checkpoint := get_tree().get_first_node_in_group("stage_checkpoint")

	if hits >= MAX_HITS or not is_instance_valid(checkpoint):
		level.set_meta("restart_pending", true)
		get_tree().reload_current_scene()
		return

	level.set_meta("damage_taken", hits)

	if on_survived.is_valid():
		on_survived.call()

	get_tree().call_group("life_counter", "update_lives", hits)

	attached = false
	detach_pending = false
	wall_slide_elapsed = 0.0
	ceiling_elapsed = 0.0
	surface_normal = Vector2.UP
	checkpoint.call("toCheckpoint", self)

	_update_sprite_pose()
	sprite.play("idle")
	sprite.show()
	death_in_progress = false
	set_physics_process(true)
