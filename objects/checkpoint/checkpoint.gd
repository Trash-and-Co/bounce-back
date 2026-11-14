extends Node2D
class_name StageCheckpoint


func toCheckpoint(player: CharacterBody2D) -> void:
	player.global_position = global_position
	player.velocity = Vector2.ZERO
	player.set("attached", false)
	player.set("dragging", false)
	player.set("detach_pending", false)
	player.set("drag_start", Vector2.ZERO)
	player.set("surface_normal", Vector2.UP)

	var sprite := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if sprite:
		sprite.flip_h = false
		sprite.flip_v = false
		sprite.play("idle")

	player.queue_redraw()
	player.set("death_in_progress", false)
