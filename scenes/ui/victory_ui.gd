extends Control

@export var player: Player
@export var game_over_anims: AnimationPlayer
@export var world_anims: AnimationPlayer
@export var high_score_label: Label
@export var coins_collected_label: Label

func _ready() -> void:
	Global.boss_defeated.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	player.shaker_component_3d.play_shake()
	await get_tree().create_timer(1.0, true).timeout
	AudioManager.bgm.stop()
	AudioManager.victory.play()
	game_over_anims.play("open")
	coins_collected_label.text = "Coins: %d" % Global.coins
	high_score_label.text = "Highest Coins: %d" % Global.highest_coins

func _on_play_again_pressed() -> void:
	Global.reset_score()
	AudioManager.ui_click.play()
	Global.auto_restart = true
	game_over_anims.play_backwards("open")
	await game_over_anims.animation_finished
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	Global.reset_score()
	AudioManager.ui_click.play()
	game_over_anims.play_backwards("open")
	await game_over_anims.animation_finished
	get_tree().paused = false
	get_tree().reload_current_scene()
