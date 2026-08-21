extends Control

@export var world_anims: AnimationPlayer
@export var player: Player

func _input(event: InputEvent) -> void:
	if Global.is_game_started: return
	if event is InputEventScreenTouch:
		if event.pressed and event.position:
			player.dust_particles.show()
			print("Screen Touched")
			world_anims.play("Intro")
			Global.is_game_started = true
			self.hide()
