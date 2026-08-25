extends Control
class_name GameUI

@export var coins_label: Label
@export var distance_label: Label
@export var pause_menu: PauseMenu

func _ready() -> void:
	Global.coin_collected.connect(on_coin_collected)

func _process(delta: float) -> void:
	if not Global.is_game_started: return
	
	Global.distance += 0.2 * delta
	distance_label.text = "%.2f km" % Global.distance

func on_coin_collected(amount: int) -> void:
	coins_label.text = "%d" % amount
	print(amount)
	if Global.coins > Global.highest_coins:
		Global.highest_coins = Global.coins
		Global.save_stats()

func _on_pause_btn_pressed() -> void:
	get_tree().paused = true
	AudioManager.ui_click.play()
	pause_menu.pause_anims.play("open", -1, 2.0)
