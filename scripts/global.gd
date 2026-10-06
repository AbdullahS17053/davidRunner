extends Node

@warning_ignore("unused_signal")
signal coin_collected(amount: int)
@warning_ignore("unused_signal")
signal game_over

@warning_ignore("unused_signal")
signal player_revived

@warning_ignore("unused_signal")
signal bonus_power_up_granted

@warning_ignore("unused_signal")
signal boss_defeated
@warning_ignore("unused_signal")
signal boss_failed
@warning_ignore("unused_signal")
signal on_boss_hit

@warning_ignore("unused_signal")
signal enemy_killed_for_coins(pos_3d: Vector3, amount: int)

#var current_coins: int = 0
var equipped_skin: SkinsData
var pending_starting_powerup: PowerupData = null

var coins: int = 0
var selected_map_index: int = 0
var can_spawn_chunks: bool = true

var total_coins: int:
	get: return SaveManager.data["stats"]["total_coins"]
	set(value): SaveManager.data["stats"]["total_coins"] = value

var highest_coins: int:
	get: return SaveManager.data.stats.high_score
	set(value): SaveManager.data.stats.high_score = value

var distance: float = 0

var auto_restart: bool = false
var is_game_started: bool = false

func _ready() -> void:
	if not AdManager.user_earned_reward.is_connected(_on_user_earned_reward):
		AdManager.user_earned_reward.connect(_on_user_earned_reward)

func reset_score() -> void:
	coins = 0
	distance = 0
	is_game_started = false

func save_stats() -> void:
	SaveManager.save_game()

func _on_user_earned_reward(reward_type: String) -> void:
	match reward_type:
		"double_coins":
			total_coins += coins
			coins *= 2
			coin_collected.emit(coins)
			if coins > highest_coins:
				highest_coins = coins
			save_stats()
		"revive":
			pass # Handled by game_over_ui.gd after ad is dismissed
		"bonus_power_up":
			bonus_power_up_granted.emit()
