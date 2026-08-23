extends CharacterBody3D

@export var animation_player: AnimationPlayer
@onready var player: Player = get_tree().get_first_node_in_group("player")
@export var wolf_snarl: AudioStreamPlayer3D

func _ready() -> void:
	Global.game_over.connect(func():
		animation_player.play("Eating")
		)
