extends Area2D

@onready var text_box = $PanelContainer
@onready var label: Label = $PanelContainer/Label 
@export_multiline var sign_text: String = "Read me!"

func _ready():
	text_box.hide()
	label.text = sign_text

func _on_body_entered(body):
	if body is CharacterBody2D:
		label.text = sign_text
		text_box.show()

func _on_body_exited(body):
	if body is CharacterBody2D:
		text_box.hide()
