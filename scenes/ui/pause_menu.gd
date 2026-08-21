extends Control

@export var settings_menu: Control

func _on_menu_btn_pressed(pressed_button: StringName) -> void:
	match pressed_button:
		&"resume": self.hide(); get_tree().paused = false
		&"settings": settings_menu.show()
		&"exit": get_tree().quit()
