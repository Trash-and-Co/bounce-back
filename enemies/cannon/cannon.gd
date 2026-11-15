extends Node2D

const PARTICLES_SCENE = preload("res://enemies/bullet & particle/summon_particles.tscn")

@export var bullet_scene: PackedScene = preload("res://enemies/bullet & particle/bullet.tscn")
@export var starts_enabled: bool = true

@onready var muzzle: Marker2D = $Muzzle
@onready var shoot_timer: Timer = $ShootTimer


func _ready() -> void:
	shoot_timer.stop()
	shoot_timer.one_shot = false

	if not shoot_timer.timeout.is_connected(_shoot):
		shoot_timer.timeout.connect(_shoot)

	if starts_enabled:
		shoot_timer.start(2.0)


func _shoot() -> void:
	var level := get_tree().current_scene
	if bullet_scene == null or level == null:
		return

	var bullet := bullet_scene.instantiate() as Node2D
	bullet.set("direction", Vector2.RIGHT.rotated(muzzle.global_rotation))
	level.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation

	var particles := PARTICLES_SCENE.instantiate() as Node2D
	level.add_child(particles)
	particles.global_position = muzzle.global_position
