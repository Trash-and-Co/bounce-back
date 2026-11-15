extends Node2D

const SAFE_SPOT_SCENE = preload("res://objects/bounce_pad/bounce_pad.tscn")
const IMPALED_ASSET = preload("res://enemies/spike/spikes_impaled.png")
const SAFE_SPOT_OFFSET: float = 8.0

@onready var spike_sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $Area2D/CollisionShape2D

var converted: bool = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if converted or not body.is_in_group("player"):
		return

	if body.call("take_damage", _convert_to_safe_spot):
		spike_sprite.texture = IMPALED_ASSET


func _convert_to_safe_spot() -> void:
	converted = true
	$Area2D.set_deferred("monitoring", false)

	var level := get_tree().current_scene
	var pad_position := _safe_spot_position()
	var safe_spot := SAFE_SPOT_SCENE.instantiate() as StaticBody2D

	safe_spot.hide()
	level.add_child(safe_spot)
	safe_spot.global_position = pad_position

	var occupied := int(level.get_meta("occupied_spikes", 0))
	level.set_meta("occupied_spikes", occupied + 1)


func _safe_spot_position() -> Vector2:
	var hazard_top := hitbox.global_position.y
	var rectangle := hitbox.shape as RectangleShape2D

	if rectangle:
		hazard_top -= rectangle.size.y * absf(hitbox.global_scale.y) * 0.5

	return Vector2(global_position.x, hazard_top + SAFE_SPOT_OFFSET)
