extends Node2D

@export var bullet_scene: PackedScene

@onready var muzzle: Marker2D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer

var bullet = preload("res://enemies/bullet & particle/bullet.tscn")
const PARTICLES_SCENE = preload("res://enemies/bullet & particle/summon_particles.tscn")

func _ready() -> void:
	if shoot_timer == null:
		return

	shoot_timer.timeout.connect(_shoot)
	shoot_timer.one_shot = false
	shoot_timer.start(2.0)

func _shoot() -> void:

	if bullet_scene == null:
		return

	if muzzle == null:
		return

	bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation
	bullet.direction = Vector2.RIGHT.rotated(muzzle.global_rotation)

	var particles = PARTICLES_SCENE.instantiate()
	particles.global_position = bullet.global_position
	get_tree().current_scene.add_child(particles)
