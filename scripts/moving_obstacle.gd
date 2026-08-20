class_name MovingObstacle
extends Node3D

@export var move_speed: float = 20.0
@export var distance_threshold: float = 1000.0
@export var direction: float = -1

@export var parent: Node3D

func _physics_process(delta: float) -> void:
	var is_on_screen = get_viewport().get_camera_3d().is_position_in_frustum(parent.global_position)
	var distance = parent.global_position.distance_squared_to(parent.player.global_position)
	if is_on_screen and distance < distance_threshold:
		parent.position.z -= direction * move_speed * delta
	else:
		return
