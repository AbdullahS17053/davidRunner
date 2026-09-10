extends Node

@warning_ignore("unused_signal")
signal coin_collected(amount: int)
@warning_ignore("unused_signal")
signal game_over

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

func reset_score() -> void:
	coins = 0
	distance = 0
	is_game_started = false

func save_stats() -> void:
	SaveManager.save_game()
