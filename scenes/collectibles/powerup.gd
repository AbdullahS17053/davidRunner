class_name Powerup
extends Area3D

@export var powerups: Array[PowerupData]

var random_powerup: PowerupData

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	random_powerup = powerups.pick_random()

	if random_powerup and random_powerup.model_scene:
		var model = random_powerup.model_scene.instantiate()
		add_child(model)

func _on_body_entered(body: Node3D) -> void:
	if body is Player and random_powerup:
		body.apply_powerup(random_powerup)
		queue_free()
