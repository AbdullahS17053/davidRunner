class_name Boss
extends CharacterBody3D

@export var coin_reward: int = 500
@export var boss_scale: float = 4.0
@export var rise_duration: float = 3.0

@export var smoke: GPUParticles3D
@export var boss_anims: AnimationPlayer
@export var boss_entrance_rumble: AudioStreamPlayer
@export var head_point: Marker3D
@export var growl: AudioStreamPlayer

var player: Player
var is_active: bool = false
var vulnerable: bool = false

func _ready() -> void:
	scale = Vector3(boss_scale, boss_scale, boss_scale)
	visible = false
	
	if boss_anims:
		boss_anims.animation_finished.connect(_on_animation_finished)

func activate(player_node: Node3D) -> void:
	player = player_node as Player
	visible = true
	
	player.heavy_shake.play_shake()
	boss_entrance_rumble.play()
	
	if boss_anims and boss_anims.has_animation("rise"):
		boss_anims.play("rise", 0.2)
	else:
		_on_landed()

func shake_camera_light() -> void:
	player.shaker_component_3d.play_shake()

func shake_camera_intense() -> void:
	player.heavy_shake.play_shake()

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name.to_lower() == "rise":
		_on_landed()

func _on_landed() -> void:
	is_active = true

	AudioManager.heavy_fall_impact.play()

	if smoke:
		smoke.restart()

	if player and player.shaker_component_3d:
		player.shaker_component_3d.play_shake()

func take_hit() -> void:
	pass

func die() -> void:
	if not vulnerable:
		return
		
	vulnerable = false
	play_defeat()
	Global.boss_defeated.emit()
	Global.enemy_killed_for_coins.emit(get_target_position(), coin_reward)

func get_target_position() -> Vector3:
	if head_point:
		return head_point.global_position
	return global_position

func play_defeat() -> void:
	is_active = false
	if boss_anims.has_animation("fall"):
		AudioManager.heavy_fall_impact.play()
		growl.play()
		boss_anims.play("fall", 0.2)

	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)

func play_attack() -> void:
	if boss_anims and boss_anims.has_animation("attack"):
		boss_anims.play("attack", 0.2)
