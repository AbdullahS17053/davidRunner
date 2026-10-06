extends Control
class_name MainMenu

@export var settings_menu: SettingsMenu
@export var menu_anims: AnimationPlayer
@export var map_select_menu: MapSelectUI
@export var shop_menu_anims: AnimationPlayer
@export var world_anims: AnimationPlayer

@export_group("Ad Bonus")
@export var available_bonus_powerups: Array[PowerupData]

func _ready() -> void:
	AdManager.user_earned_reward.connect(_on_user_earned_reward)

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

func _on_bonus_powerup_btn_pressed() -> void:
	AudioManager.ui_click.play()
	print("Bonus Powerup Ad Requested")
	
	if AdManager.is_rewarded_ad_loaded():
		AdManager.show_rewarded_ad("bonus_powerup")
	else:
		print("Rewarded ad not loaded yet. Attempting to load...")
		AdManager.load_rewarded_ad()

func _on_user_earned_reward(reward_type: String) -> void:
	print(reward_type)
	if reward_type == "bonus_powerup" and not available_bonus_powerups.is_empty():
		Global.pending_starting_powerup = available_bonus_powerups.pick_random()
		print("Bonus powerup granted for the next run: ", Global.pending_starting_powerup)
