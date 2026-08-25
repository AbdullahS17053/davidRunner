class_name Boss
extends CharacterBody3D

@export var drop_height: float = 30.0
@export var target_distance_ahead: float = 12.0
@export var fall_duration: float = 0.8
@export var walk_speed: float = 2.5
@export var sprint_speed: float = 8.0
@export var attack_distance: float = 2.0

@export var smoke: GPUParticles3D
@export var boss_anims: AnimationPlayer
@export var animation_player: AnimationPlayer

@onready var player: Player = get_tree().get_first_node_in_group("player")

var is_active: bool = false
var is_stunned: bool = false
var is_falling: bool = false
var is_charging_player: bool = false

func _ready() -> void:
	Global.boss_failed.connect(func(): is_active = false)
	Global.boss_defeated.connect(func(): is_active = false)
	
	if animation_player:
		animation_player.set_blend_time("HitReact", "Walk", 0.2)
		animation_player.animation_finished.connect(func(anim_name: StringName):
			if anim_name == "HitReact":
				is_stunned = false
		)

	Global.on_boss_hit.connect(func():
		if is_active and not is_stunned:
			is_stunned = true
			animation_player.play("HitReact", 0.2)
			animation_player.queue("Walk")
	)

func _physics_process(delta: float) -> void:
	if not player or is_stunned:
		return
		
	global_position.x = lerp(global_position.x, player.global_position.x, 15.0 * delta)
	
	if is_falling:
		global_position.z = player.global_position.z - target_distance_ahead
		return
		
	if not is_active:
		return
		
	# Determine speed: normal walk or fast charge
	var current_speed = sprint_speed if is_charging_player else walk_speed
	global_position.z += current_speed * delta
	
	if global_position.distance_to(player.global_position) <= attack_distance:
		# If we were charging because of a time-out, finish the attack now
		if is_charging_player:
			is_charging_player = false
			trigger_attack_sequence()
			return
			
		# Normal distance-based failure
		var boss_ui = get_tree().get_first_node_in_group("boss_ui")
		if boss_ui and boss_ui.has_method("end_fight"):
			boss_ui.end_fight(false)

func spawn_from_sky(player_node: Node3D) -> void:
	is_falling = true
	global_position = Vector3(player_node.global_position.x, drop_height, player_node.global_position.z - target_distance_ahead)
	visible = true
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "global_position:y", 0.0, fall_duration)
	tween.finished.connect(_on_landed)

func trigger_attack_sequence() -> void:
	is_active = false
	
	var boss_ui = get_tree().get_first_node_in_group("boss_ui")
	if boss_ui:
		boss_ui.is_active = false
		boss_ui.visible = false
		
	play_attack()
	await get_tree().create_timer(0.5).timeout
	Global.game_over.emit()

func force_charge_attack() -> void:
	if not is_active:
		return
		
	is_charging_player = true
	
	if animation_player and animation_player.has_animation("Run"):
		animation_player.play("Run", 0.2)
	elif animation_player and animation_player.has_animation("Walk"):
		animation_player.play("Walk", 0.2)

func _on_landed() -> void:
	is_falling = false
	is_active = true
	
	AudioManager.heavy_fall_impact.play()

	if smoke:
		smoke.restart()
		
	if player.shaker_component_3d:
		player.shaker_component_3d.play_shake()
		
	if animation_player:
		animation_player.play("Walk", 0.2)

func play_defeat() -> void:
	is_active = false
	if boss_anims.has_animation("death"):
		boss_anims.play("death")
	
	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)

func play_attack() -> void:
	if animation_player and animation_player.has_animation("Punch"):
		animation_player.play("Punch", 0.2)
