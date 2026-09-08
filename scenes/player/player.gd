class_name Player
extends CharacterBody3D

@export var move_speed: float = 12.0
@export var jump_force: float = 8.0

@export_group("Touch Controls")
@export var swipe_threshold: float = 50.0

@export_group("Difficulty Settings")
@export var max_speed: float = 40.0
@export var acceleration: float = 0.1

@export_group("Lane Settings")
@export var lane_width: float = 2.5
@export var switch_speed: float = 15.0

@export_group("Slide Settings")
@export var slide_duration: float = 0.8
@export var fast_fall_force: float = 15.0

@export_group("References")
@export var col_shape: CollisionShape3D
@export var animation_tree: AnimationTree
@export var animation_playback: AnimationNodeStateMachinePlayback
@export var dust_particles: GPUParticles3D
@export var slide_particles: GPUParticles3D
@export var player_anims: AnimationPlayer
@export var heavy_shake: ShakerComponent3D
@export var shaker_component_3d: ShakerComponent3D
@export var physical_bone_simulator_3d: PhysicalBoneSimulator3D
@export_subgroup("Projectile")
@export var projectile_scene: PackedScene
@export var projectile_spawn_point: Marker3D

var is_swiping: bool = false
var touch_start_pos: Vector2 = Vector2.ZERO

var current_lane: int = 0
var is_sliding: bool = false
var slide_timer: float = 0.0

var is_jumping: bool = false
var is_switching_left: bool = false
var is_switching_right: bool = false

var normal_height: float
var normal_pos_y: float

var is_dead: bool = false
var game_start: bool = false
var is_shooting: bool = false

func _ready() -> void:
	is_dead = false
	global_position.x = 0.0
	
	col_shape.shape = col_shape.shape.duplicate()
	
	normal_height = col_shape.shape.height
	normal_pos_y = col_shape.position.y

func _input(event: InputEvent) -> void:
	if not Global.is_game_started: return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			is_swiping = true
			touch_start_pos = event.position
		else:
			is_swiping = false
			
	elif event is InputEventScreenDrag and is_swiping:
		var swipe_dir: Vector2 = event.position - touch_start_pos
		
		if swipe_dir.length() >= swipe_threshold:
			is_swiping = false
			
			if abs(swipe_dir.x) > abs(swipe_dir.y):
				if swipe_dir.x > 0:
					simulate_input("right")
				else:
					simulate_input("left")
			else:
				if swipe_dir.y > 0:
					simulate_input("slide")
				else:
					simulate_input("jump")

func _physics_process(delta: float) -> void:
	if not Global.is_game_started: return
	
	game_start = Global.is_game_started
	
	if move_speed < max_speed:
		move_speed += acceleration * delta
		move_speed = min(move_speed, max_speed)
	
	if not is_on_floor():
		dust_particles.emitting = false
		velocity += get_gravity() * delta * 2.0
		
		if Input.is_action_just_pressed("slide"):
			is_jumping = false
			velocity.y = -fast_fall_force 
	else:
		is_jumping = false
		dust_particles.emitting = true
		
		if Input.is_action_just_pressed("jump"):
			is_jumping = true
			velocity.y = jump_force
			stop_slide()
			
		if Input.is_action_just_pressed("slide") and not is_sliding:
			is_jumping = false
			start_slide()

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			stop_slide()

	velocity.z = 0.0
	
	is_switching_left = Input.is_action_just_pressed("left")
	is_switching_right = Input.is_action_just_pressed("right")
	
	if is_switching_left:
		current_lane = max(current_lane - 1, -1)
	elif is_switching_right:
		current_lane = min(current_lane + 1, 1)

	var target_x: float = current_lane * lane_width
	var dynamic_switch = switch_speed * (move_speed / 12.0) 
	var new_x: float = lerpf(global_position.x, target_x, dynamic_switch * delta)
	velocity.x = (new_x - global_position.x) / delta
	
	move_and_slide()

func start_slide() -> void:
	is_sliding = true
	slide_timer = slide_duration
	
	col_shape.shape.height = normal_height / 2.0
	col_shape.position.y = normal_pos_y - (normal_height / 4.0)

func stop_slide() -> void:
	if not is_sliding: return
	is_sliding = false
	
	col_shape.shape.height = normal_height
	col_shape.position.y = normal_pos_y

func simulate_input(action_name: String) -> void:
	var press_event = InputEventAction.new()
	press_event.action = action_name
	press_event.pressed = true
	Input.parse_input_event(press_event)
	
	var release_event = InputEventAction.new()
	release_event.action = action_name
	release_event.pressed = false
	Input.parse_input_event(release_event)

func reset_for_boss() -> void:
	game_start = false
	position.y = 0.0 
	velocity = Vector3.ZERO
	dust_particles.emitting = false
	slide_particles.emitting = false

	current_lane = 0
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	is_jumping = false
	is_sliding = false

func player_death() -> void:
	is_dead = true
	shaker_component_3d.play_shake()
	Global.is_game_started = false
	dust_particles.emitting = false
	player_anims.play("death")
	AudioManager.fail.play()
	AudioManager.bgm.stop()
	AudioManager.death_impact.play()
	physical_bone_simulator_3d.physical_bones_start_simulation()
	Global.total_coins += Global.coins
	Global.save_stats()

func shoot_at_target(target_node: Node3D) -> void:
	if is_shooting:
		return
		
	is_shooting = true
	animation_tree["parameters/slingshot_oneshot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	
	await get_tree().create_timer(0.4).timeout
	
	if not is_inside_tree():
		is_shooting = false
		return
		
	if is_instance_valid(target_node) and projectile_scene and projectile_spawn_point:
		var projectile: Projectile = projectile_scene.instantiate() as Projectile
		get_parent().add_child(projectile)
		
		projectile.global_position = projectile_spawn_point.global_position
		projectile.fire_at(target_node)
		
	await get_tree().create_timer(0.5).timeout
	
	is_shooting = false

func play_slingshot_animation() -> void:
	animation_tree["parameters/slingshot_oneshot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func _on_collision_body_entered(body: Node3D) -> void:
	if body.is_in_group("obstacle"):
		Global.game_over.emit()
