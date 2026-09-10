extends Control
class_name MainMenu

@export var settings_menu: SettingsMenu
@export var menu_anims: AnimationPlayer
@export var map_select_menu: MapSelectUI
@export var shop_menu_anims: AnimationPlayer
@export var world_anims: AnimationPlayer

func _on_settings_btn_pressed() -> void:
	AudioManager.ui_click.play()
	settings_menu.settings_anims.play("open")

func _on_exit_btn_pressed() -> void:
	AudioManager.ui_click.play()
	get_tree().quit()

func _on_maps_btn_pressed() -> void:
	AudioManager.ui_click.play()
	map_select_menu.map_select_anims.play("open")

func _on_shop_btn_pressed() -> void:
	AudioManager.ui_click.play()
	menu_anims.play("exit")
	shop_menu_anims.play("open")
	world_anims.play("store_camera")
