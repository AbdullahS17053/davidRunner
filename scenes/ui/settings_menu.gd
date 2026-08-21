extends Control
class_name SettingsMenu

@export var settings_anims: AnimationPlayer

func _on_close_btn_pressed() -> void:
	settings_anims.play("exit")
