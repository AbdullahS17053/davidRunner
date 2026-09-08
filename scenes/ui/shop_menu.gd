extends Control

@export var shop_menu_anims: AnimationPlayer

func _on_close_btn_pressed() -> void:
	AudioManager.ui_click.play()
	shop_menu_anims.play("exit")
