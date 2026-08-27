extends Node3D
class_name Projectile

@export var speed: float = 50.0
var target: Node3D

func fire_at(target_node: Node3D) -> void:
	target = target_node

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
		
	var target_pos: Vector3 = target.global_position
	if target.has_method("get_target_position"):
		target_pos = target.get_target_position()
		
	var distance_to_target = global_position.distance_to(target_pos)
	var move_step = speed * delta
	
	if distance_to_target <= move_step or distance_to_target < 1.5:
		var hit_node = target
		while hit_node != null:
			if hit_node.has_method("die"):
				hit_node.die()
				break
			hit_node = hit_node.get_parent()
			
		queue_free()
		return
		
	var direction = (target_pos - global_position).normalized()
	global_position += direction * move_step
