extends CharacterBody2D

@export var launch_power: float = 6.0
@export var max_drag: float = 120.0

var attached: bool = false
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:
			var mouse := get_global_mouse_position()

			if attached and mouse.distance_to(global_position) <= 40.0:
				dragging = true
				drag_start = mouse

		elif dragging:
			dragging = false
			var pull := drag_start - get_global_mouse_position()
			pull = pull.limit_length(max_drag)

			if pull.length() >= 8.0:
				velocity = pull * launch_power

				if velocity.x != 0.0:
					$AnimatedSprite2D.flip_h = velocity.x < 0.0

				attached = false


func _physics_process(delta: float) -> void:
	if not attached:
		velocity += get_gravity() * delta

		var collision := move_and_collide(velocity * delta)

		if collision:
			velocity = Vector2.ZERO
			attached = true

	queue_redraw()


func _draw() -> void:
	if dragging:
		var pull := get_global_mouse_position() - drag_start
		pull = pull.limit_length(max_drag)
		draw_line(Vector2.ZERO, pull, Color.YELLOW, 3.0)
		draw_circle(pull, 5.0, Color.YELLOW)
		
func _ready() -> void:
	$AnimatedSprite2D.play("idle")
