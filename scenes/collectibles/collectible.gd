class_name Collectible
extends Area3D

@export var spin_speed: float = 3.0
@export var bob_height: float = 0.25 
@export var bob_speed: float = 4.0

@export var animation_player: AnimationPlayer

var start_y: float
var time_passed: float = 0.0

func _ready() -> void:
	start_y = position.y
	time_passed = randf() * PI * 2
	
	if not self.body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
	
	time_passed += delta * bob_speed
	position.y = start_y + (sin(time_passed) * bob_height)

func _on_body_entered(body: Node3D) -> void:
	if body is Player and Global.is_game_started:
		Global.coins += 1
		AudioManager.play_coin_sound()
		animation_player.play("collect")
		Global.coin_collected.emit(Global.coins)
