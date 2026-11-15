extends CanvasLayer

@onready var icons: Array[TextureRect] = [
	$Lives/Live1,
	$Lives/Live2,
	$Lives/Live3
]


func _ready() -> void:
	add_to_group("life_counter")
	update_lives(0)


func update_lives(occupied: int) -> void:
	for index in range(icons.size()):
		if index >= icons.size() - occupied:
			icons[index].self_modulate = Color.BLACK
		else:
			icons[index].self_modulate = Color.WHITE
