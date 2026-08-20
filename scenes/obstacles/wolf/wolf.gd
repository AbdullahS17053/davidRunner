extends CharacterBody3D

@export var animation_player: AnimationPlayer
@onready var player: Player = get_tree().get_first_node_in_group("player")
