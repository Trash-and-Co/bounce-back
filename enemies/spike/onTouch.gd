extends Node2D

const SAFE_SPOT_SCENE = preload("res://objects/bounce_pad/bounce_pad.tscn")
const MAX_OCCUPIED_SPIKES: int = 3
const IMPACT_TIME: float = 0.14
const HOLD_TIME: float = 1.0
const SAFE_SPOT_OFFSET: float = 8.0
const SQUASHED_SPRITE_OFFSET: float = -14.0

@onready var spike_sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $Area2D/CollisionShape2D

var converted: bool = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if converted or not body.is_in_group("player"):
		return

	var level := get_tree().current_scene
	if level == null or level.get_meta("restart_pending", false):
		return

	if not body.call("claim_death"):
		return

	body.set_physics_process(false)
	_play_impact.call_deferred(body, level)


func _play_impact(player: CharacterBody2D, level: Node) -> void:
	if not is_instance_valid(player) or get_tree().current_scene != level:
		return

	var occupied := int(level.get_meta("occupied_spikes", 0))
	var checkpoint := get_tree().get_first_node_in_group("stage_checkpoint")
	var sprite: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
	var original_scale := sprite.scale
	var pad_position := _safe_spot_position()
	var impact_position := pad_position + Vector2(0.0, SQUASHED_SPRITE_OFFSET)
	impact_position -= sprite.global_position - player.global_position

	player.velocity = Vector2.ZERO
	sprite.flip_h = false
	sprite.flip_v = false
	sprite.play("idle")
	sprite.frame = 1
	sprite.pause()

	var squash := create_tween().set_parallel()
	squash.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	squash.tween_property(player, "global_position", impact_position, IMPACT_TIME)
	squash.tween_property(sprite, "scale", Vector2(5.0, 2.0), IMPACT_TIME)
	await squash.finished
	await get_tree().create_timer(HOLD_TIME, false).timeout

	if not is_instance_valid(player) or get_tree().current_scene != level:
		return

	if occupied + 1 >= MAX_OCCUPIED_SPIKES or not is_instance_valid(checkpoint):
		level.set_meta("restart_pending", true)
		get_tree().reload_current_scene()
		return

	converted = true
	$Area2D.set_deferred("monitoring", false)
	spike_sprite.modulate = Color(0.35, 0.4, 0.45, 1.0)

	var safe_spot := SAFE_SPOT_SCENE.instantiate() as StaticBody2D
	level.add_child(safe_spot)
	safe_spot.global_position = pad_position

	level.set_meta("occupied_spikes", occupied + 1)
	get_tree().call_group("life_counter", "update_lives", occupied + 1)
	sprite.scale = original_scale
	checkpoint.call("toCheckpoint", player)
	player.set_physics_process(true)


func _safe_spot_position() -> Vector2:
	var hazard_top := hitbox.global_position.y
	var rectangle := hitbox.shape as RectangleShape2D
	if rectangle:
		hazard_top -= rectangle.size.y * absf(hitbox.global_scale.y) * 0.5

	return Vector2(global_position.x, hazard_top + SAFE_SPOT_OFFSET)
