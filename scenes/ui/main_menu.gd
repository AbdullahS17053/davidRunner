extends Control
class_name MainMenu

@export var world_anims: AnimationPlayer
@export var player: Player
@export var settings_menu: SettingsMenu
@export var coins_label: Label
@export var menu_anims: AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_game_started: return
	if event is InputEventScreenTouch:
		if event.pressed and event.position:
			player.dust_particles.show()
			world_anims.play("Intro")
			Global.is_game_started = true
			AudioManager.bgm.play()

func _process(_delta: float) -> void:
	coins_label.text = "%d" % Global.total_coins

func _on_settings_btn_pressed() -> void:
	AudioManager.ui_click.play()
	settings_menu.settings_anims.play("open")
