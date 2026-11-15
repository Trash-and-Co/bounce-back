extends Area2D

@export_file("*.tscn") var next_stage: String

var changing_stage := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if changing_stage or not body.is_in_group("player"):
		return

	if next_stage.is_empty():
		push_warning("Choose a Next Stage for " + name)
		return

	changing_stage = true
	_change_stage.call_deferred()


func _change_stage() -> void:
	var result := get_tree().change_scene_to_file(next_stage)
	if result != OK:
		changing_stage = false
		push_error("Could not load stage: " + next_stage)
