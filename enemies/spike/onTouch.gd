extends Node2D

const SAFE_SPOT_SCENE = preload("res://objects/bounce_pad/bounce_pad.tscn")
const MAX_OCCUPIED_SPIKES: int = 3

var converted: bool = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if converted or not body.is_in_group("player"):
		return

	var level := get_tree().current_scene

	if level.get_meta("restart_pending", false):
		return

	if not body.call("claim_death"):
		return

	var occupied: int = int(level.get_meta("occupied_spikes", 0))

	if occupied >= MAX_OCCUPIED_SPIKES:
		level.set_meta("restart_pending", true)
		get_tree().call_deferred("reload_current_scene")
		return

	level.set_meta("occupied_spikes", occupied + 1)
	converted = true
	$Area2D.set_deferred("monitoring", false)
	_create_safe_spot.call_deferred(body)


func _create_safe_spot(body: Node2D) -> void:
	var spike_shape: CollisionShape2D = $Area2D/CollisionShape2D
	var rectangle := spike_shape.shape as RectangleShape2D
	var hazard_top := spike_shape.global_position.y

	if rectangle:
		hazard_top -= rectangle.size.y * absf(spike_shape.global_scale.y) * 0.5

	var safe_spot := SAFE_SPOT_SCENE.instantiate() as StaticBody2D
	get_tree().current_scene.add_child(safe_spot)
	safe_spot.global_position = Vector2(global_position.x, hazard_top + 8.0)

	$Sprite2D.modulate = Color(0.35, 0.4, 0.45, 1.0)

	if is_instance_valid(body):
		get_tree().call_group_flags(
			SceneTree.GROUP_CALL_DEFERRED,
			"stage_checkpoint",
			"toCheckpoint",
			body
		)
