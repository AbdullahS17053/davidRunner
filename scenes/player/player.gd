class_name Player extends CharacterBody3D

@export var move_speed: float = 12.0
@export var jump_force: float = 8.0

@export_group("Lane Settings")
@export var lane_width: float = 2.5
@export var switch_speed: float = 15.0

var current_lane: int = 0

func _ready() -> void:
	global_position.x = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * 2.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force
	
	velocity.z = -move_speed
	
	if Input.is_action_just_pressed("left"):
		current_lane = max(current_lane - 1, -1)
	elif Input.is_action_just_pressed("right"):
		current_lane = min(current_lane + 1, 1)

	var target_x: float = current_lane * lane_width
	var new_x: float = lerpf(global_position.x, target_x, switch_speed * delta)
	
	velocity.x = (new_x - global_position.x) / delta
	move_and_slide()

func _on_collision_body_entered(body: Node3D) -> void:
	if body.is_in_group("obstacle"):
		get_tree().reload_current_scene.call_deferred()
