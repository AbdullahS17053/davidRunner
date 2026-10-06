class_name Powerup
extends Area3D

@export var spin_speed: float = 3.0
@export var bob_height: float = 0.25 
@export var bob_speed: float = 4.0
@export var powerups: Array[PowerupData]

var start_y: float
var time_passed: float = 0.0

var data: PowerupData

func _ready() -> void:
	start_y = position.y
	time_passed = randf() * PI * 2
	
	body_entered.connect(_on_body_entered)
	
	if not data and powerups.size() > 0:
		data = powerups.pick_random()
		
	if data and data.model_scene:
		var model = data.model_scene.instantiate()
		add_child(model)

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
	
	time_passed += delta * bob_speed
	position.y = start_y + (sin(time_passed) * bob_height)

func _on_body_entered(body: Node3D) -> void:
	if body is Player and data:
		AudioManager.powerup_pickup.play()
		body.apply_powerup(data)
		queue_free()
