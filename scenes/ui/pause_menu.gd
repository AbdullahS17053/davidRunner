extends Control
class_name PauseMenu

@export var settings_menu: Control
@export var pause_anims: AnimationPlayer

func _on_menu_btn_pressed(pressed_button: StringName) -> void:
	AudioManager.ui_click.play()
	match pressed_button:
		&"resume":
			pause_anims.play("exit", -1, 2.0)
			get_tree().paused = false
		&"settings": settings_menu.settings_anims.play("open")
		&"exit": get_tree().quit()
