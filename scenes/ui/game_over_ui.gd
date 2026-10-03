class_name GameOverUI
extends Control

@export var game_over_anims: AnimationPlayer
@export var world_anims: AnimationPlayer
@export var high_score_label: Label
@export var coins_collected_label: Label

var _watching_2x_ad: bool = false
var _earned_2x_coins: bool = false
var _watching_revive_ad: bool = false
var _earned_revive: bool = false


func _ready() -> void:
	Global.game_over.connect(_on_game_over)
	AdManager.user_earned_reward.connect(_on_user_earned_reward)
	AdManager.rewarded_ad_dismissed.connect(_on_rewarded_ad_dismissed)

func _on_user_earned_reward(reward_type: String) -> void:
	if reward_type == "double_coins" and _watching_2x_ad:
		_earned_2x_coins = true
	elif reward_type == "revive" and _watching_revive_ad:
		_earned_revive = true

func _on_rewarded_ad_dismissed() -> void:
	if _watching_2x_ad:
		_watching_2x_ad = false
		if _earned_2x_coins:
			_earned_2x_coins = false
			_on_main_menu_pressed()
	elif _watching_revive_ad:
		_watching_revive_ad = false
		if _earned_revive:
			_earned_revive = false
			game_over_anims.play_backwards("open")
			Global.player_revived.emit()


func _on_game_over() -> void:
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

func _on_2x_coins_pressed() -> void:
	if AdManager.is_rewarded_ad_loaded():
		_watching_2x_ad = true
		_earned_2x_coins = false
	AdManager.show_rewarded_ad("double_coins")

func _on_revive_pressed() -> void:
	if AdManager.is_rewarded_ad_loaded():
		_watching_revive_ad = true
		_earned_revive = false
	AdManager.show_rewarded_ad("revive")
