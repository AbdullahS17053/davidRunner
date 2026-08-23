class_name GameOverUI
extends Control

@export var game_over_anims: AnimationPlayer
@export var world_anims: AnimationPlayer
@export var high_score_label: Label
@export var coins_collected_label: Label

func _ready() -> void:
	Global.game_over.connect(_on_game_over)

func _on_game_over() -> void:
	print("GAME OVER!")
	game_over_anims.play("open")
	coins_collected_label.text = "Coins: %d" % Global.coins
	high_score_label.text = "Highest Coins: %d" % Global.highest_coins

func _on_restart_btn_pressed() -> void:
	Global.reset_score()
	AudioManager.ui_click.play()
	Global.auto_restart = true
	game_over_anims.play_backwards("open")
	await game_over_anims.animation_finished
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	Global.reset_score()
	AudioManager.ui_click.play()
	game_over_anims.play_backwards("open")
	await game_over_anims.animation_finished
	get_tree().reload_current_scene()
