class_name Collectible
extends Area3D

@export var spin_speed: float = 3.0
@export var bob_height: float = 0.25 
@export var bob_speed: float = 4.0

@export var animation_player: AnimationPlayer

var start_y: float
var time_passed: float = 0.0

var is_magnetized: bool = false
var target_player: Node3D = null

func _ready() -> void:
	add_to_group("coin")
	start_y = position.y
	time_passed = randf() * PI * 2
	
	if not self.body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)
	
	if is_magnetized and is_instance_valid(target_player):
		var target_pos = target_player.global_position + Vector3(0, 1, 0) # Pull towards center of player
		global_position = global_position.move_toward(target_pos, 30.0 * delta)
	else:
		time_passed += delta * bob_speed
		position.y = start_y + (sin(time_passed) * bob_height)

func _on_body_entered(body: Node3D) -> void:
	if body is Player and Global.is_game_started:
		var coin_value = 2 if body.has_double_coins else 1
		Global.coins += coin_value
		AudioManager.play_coin_sound()
		animation_player.play("collect")
		Global.coin_collected.emit(Global.coins)
