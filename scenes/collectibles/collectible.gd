extends Area3D
class_name Collectible

@export var ground_check: RayCast3D
@export var shadow_decal: Decal

func _ready() -> void:
	if not self.body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	if ground_check.is_colliding():
		shadow_decal.global_position.y = ground_check.get_collision_point().y

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		Global.coins += 1
		Global.coin_collected.emit(Global.coins)
		self.queue_free()
