extends Area2D

@export var speed: float = 300.0
@export var lifetime: float = 5.0

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	age += delta

	if age >= lifetime:
		queue_free()
		return

	global_position += direction * speed * delta


func _on_body_entered(_body: Node2D) -> void:
	queue_free()
