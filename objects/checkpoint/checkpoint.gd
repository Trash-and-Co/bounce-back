extends Node2D
class_name StageCheckpoint

func toCheckpoint(player: CharacterBody2D)-> void:
	player.global_position = global_position
	player.velocity = Vector2.ZERO
