extends Control

@export var coins_label: Label
@export var distance_label: Label

func _ready() -> void:
	Global.coin_collected.connect(on_coin_collected)

func _process(delta: float) -> void:
	Global.distance += 0.2 * delta
	distance_label.text = "%.2f m" % Global.distance

func on_coin_collected(amount: int) -> void:
	coins_label.text = "%d" % amount
