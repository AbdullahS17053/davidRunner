extends Node

signal coin_collected(amount: int)

var coins: int = 0
var distance: float = 0

func reset_score() -> void:
	coins = 0
	distance = 0
