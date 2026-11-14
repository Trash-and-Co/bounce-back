extends Area2D


func _on_body_entered(body: Node2D) -> void:
	var player := body as CharacterBody2D
	if player == null or not player.is_in_group("player"):
		return

	var camera := player.get_node("Camera2D") as Camera2D
	var fade := get_tree().current_scene.get_node("FadeToBlack")

	if not player.call("claim_death"):
		return

	# Hold the camera in place while the slime keeps falling.
	var camera_offset := camera.position
	var frozen_position := camera.global_position
	camera.top_level = true
	camera.global_position = frozen_position

	player.set("attached", false)
	player.set("detach_pending", false)

	await fade.call("fade_to_black")

	# Teleport and restore camera follow while the screen is black.
	get_tree().call_group("stage_checkpoint", "toCheckpoint", player)
	player.set("attached", false)
	player.set("detach_pending", false)

	camera.top_level = false
	camera.position = camera_offset
	camera.reset_smoothing()
	camera.force_update_scroll()

	await fade.call("fade_from_black")
	player.set("death_in_progress", false)
