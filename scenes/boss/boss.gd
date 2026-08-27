class_name Boss
extends CharacterBody3D

@export var boss_scale: float = 4.0
@export var rise_duration: float = 3.0

@export var smoke: GPUParticles3D
@export var boss_anims: AnimationPlayer
@export var boss_entrance_rumble: AudioStreamPlayer

var player: Player
var is_active: bool = false

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
		boss_anims.play_section_with_markers("rise", "rise", "death")
	else:
		_on_landed()

func shake_camera_light() -> void:
	player.shaker_component_3d.play_shake()

func shake_camera_intense() -> void:
	player.heavy_shake.play_shake()

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Rise":
		_on_landed()

func _on_landed() -> void:
	is_active = true

	AudioManager.heavy_fall_impact.play()

	if smoke:
		smoke.restart()

	if player and player.shaker_component_3d:
		player.shaker_component_3d.play_shake()

func play_defeat() -> void:
	is_active = false
	if boss_anims.has_animation("fall"):
		AudioManager.heavy_fall_impact.play()
		boss_anims.play("fall")

	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(queue_free)

func play_attack() -> void:
	if boss_anims and boss_anims.has_animation("Punch"):
		boss_anims.play("Punch", 0.2)
		if player and player.has_method("player_death"):
			player.player_death()
