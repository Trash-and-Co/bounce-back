extends GPUParticles2D

func _ready() -> void:
	z_index = 50
	restart()
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
