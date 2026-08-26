class_name Boss
extends CharacterBody3D

@export var rise_depth: float = -50.0
@export var target_distance_ahead: float = 18.0
@export var rise_duration: float = 1.5
@export var boss_scale: float = 4.0

@export var smoke: GPUParticles3D
@export var boss_anims: AnimationPlayer
@export var animation_player: AnimationPlayer

@onready var player: Player = get_tree().get_first_node_in_group("player")

var is_active: bool = false
var is_rising: bool = false

func _ready() -> void:
	scale = Vector3(boss_scale, boss_scale, boss_scale)

func rise_from_abyss(player_node: Node3D) -> void:
	is_rising = true
	var target_z: float = player_node.global_position.z - target_distance_ahead
	var target_position: Vector3 = Vector3(player_node.global_position.x, 0, target_z)

	global_position = target_position + Vector3(0, rise_depth, 0)
	visible = true

	if animation_player:
		animation_player.play("JumpIdl", 0.2)

	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position:y", 0.0, rise_duration)
	tween.finished.connect(_on_landed)

func _on_landed() -> void:
	is_rising = false
	is_active = true

	AudioManager.heavy_fall_impact.play()

	if smoke:
		smoke.restart()

	if player.shaker_component_3d:
		player.shaker_component_3d.play_shake()

	#if animation_player:
		#animation_player.play("Roar", 0.2)

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
		if player and player.has_method("player_death"):
			player.player_death()
