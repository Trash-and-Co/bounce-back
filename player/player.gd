extends CharacterBody2D

@export var launch_power: float = 6.0
@export var max_drag: float = 120.0
@export var ground_friction: float = 1800.0

var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			var mouse := get_global_mouse_position()

			if is_on_floor() and mouse.distance_to(global_position) <= 40.0:
				dragging = true
				drag_start = mouse
				velocity = Vector2.ZERO

		elif dragging:
			dragging = false
			var pull := drag_start - get_global_mouse_position()
			velocity = pull.limit_length(max_drag) * launch_power


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor() and velocity.y >= 0.0:
		velocity.x = move_toward(
			velocity.x,
			0.0,
			ground_friction * delta
		)

	move_and_slide()
	queue_redraw()


func _draw() -> void:
	if dragging:
		var pull := get_global_mouse_position() - drag_start
		pull = pull.limit_length(max_drag)
		draw_line(Vector2.ZERO, pull, Color.YELLOW, 3.0)
		draw_circle(pull, 5.0, Color.YELLOW)
