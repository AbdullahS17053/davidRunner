extends Node

@export var collect_coin: AudioStreamPlayer
@export var footsteps: AudioStreamPlayer
@export var jump: AudioStreamPlayer
@export var slide: AudioStreamPlayer
@export var bgm: AudioStreamPlayer
@export var ui_click: AudioStreamPlayer
@export var death_impact: AudioStreamPlayer
@export var fail: AudioStreamPlayer
@export var wolf_snarl: AudioStreamPlayer
@export var punch: AudioStreamPlayer

@export_group("Coin Pitch Settings")
@export var base_pitch: float = 1.0
@export var pitch_step: float = 0.05  
@export var max_pitch: float = 2.0    
@export var combo_timeout: float = 0.4 

var current_pitch: float = 1.0
var time_since_last_coin: float = 0.0

func _process(delta: float) -> void:
	if current_pitch > base_pitch:
		time_since_last_coin += delta
		
		if time_since_last_coin >= combo_timeout:
			current_pitch = base_pitch

func play_coin_sound() -> void:
	if collect_coin == null:
		return
		
	collect_coin.pitch_scale = current_pitch
	collect_coin.play()
	current_pitch = min(current_pitch + pitch_step, max_pitch)
	time_since_last_coin = 0.0
