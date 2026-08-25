class_name Wolf
extends CharacterBody3D

@export var can_move: bool = true
@export var move_speed: float = 3.0
@export var distance_threshold: float = 1000.0
@export var direction: float = -1

@export var animation_player: AnimationPlayer
@export var collision_shape_3d: CollisionShape3D
@export var click_particles: GPUParticles3D
@export var wolf_howl: AudioStreamPlayer3D
@export var tap_to_kill_text_mesh: MeshInstance3D
@export var sub_viewport: SubViewport

@onready var player: Player = get_tree().get_first_node_in_group("player")

var is_dead: bool = false
var is_on_screen: bool = false

func _ready() -> void:
	if can_move:
		animation_player.play("Gallop")
	else:
		animation_player.play("Idle")

	Global.game_over.connect(func():
		if not is_dead:
			animation_player.play("Eating")
	)

func _physics_process(delta: float) -> void:
	if not Global.is_game_started or is_dead or not player: 
		return
		
	var camera: Camera3D = get_viewport().get_camera_3d()
	if not camera:
		return
		
	var distance: float = global_position.distance_squared_to(player.global_position)
	
	if is_on_screen and distance < distance_threshold:
		if can_move:
			if not AudioManager.wolf_howl.playing:
				AudioManager.wolf_howl.play()
			position.z -= direction * move_speed * delta

func stop_moving() -> void:
	can_move = false
	animation_player.play("Idle", 0.2)

func _on_click_detection_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if is_dead:
		return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dead = true
			AudioManager.wolf_snarl.play()
			AudioManager.punch.play()
			click_particles.restart()
			player.shaker_component_3d.play_shake()
			Global.coins += randi_range(5, 10)
			Global.coin_collected.emit(Global.coins)
			animation_player.play("Death")
			collision_shape_3d.set_deferred("disabled", true)

func _on_visible_on_screen_enabler_3d_screen_entered() -> void:
	is_on_screen = true

func _on_visible_on_screen_enabler_3d_screen_exited() -> void:
	is_on_screen = false
