extends Control
class_name MainMenu

@export var settings_menu: SettingsMenu
@export var menu_anims: AnimationPlayer

func _on_settings_btn_pressed() -> void:
	AudioManager.ui_click.play()
	settings_menu.settings_anims.play("open")

func _on_exit_btn_pressed() -> void:
	get_tree().quit()
