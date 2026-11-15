extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0


func _ready() -> void:
	print("Bullet spawned: ", get_script().resource_path)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction.normalized() * speed * delta

	age += delta
	if age >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_queued_for_deletion():
		return

	print("Bullet hit: ", body.name, " (", body.get_class(), ")")

	if body is CharacterBody2D and body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage")

	queue_free()
