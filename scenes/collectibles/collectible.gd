extends Area3D
class_name Collectible

func _ready() -> void:
	if not self.body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		AudioManager.play_coin_sound()
		Global.coins += 1
		Global.coin_collected.emit(Global.coins)
		self.queue_free()
