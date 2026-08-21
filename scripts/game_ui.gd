extends Control

@export var coins_label: Label
@export var distance_label: Label
@export var pause_menu: Control

func _ready() -> void:
	Global.coin_collected.connect(on_coin_collected)

func _process(delta: float) -> void:
	if not Global.is_game_started: return
	
	Global.distance += 0.2 * delta
	distance_label.text = "%.2f km" % Global.distance

func on_coin_collected(amount: int) -> void:
	coins_label.text = "%d" % amount

func _on_pause_btn_pressed() -> void:
	get_tree().paused = true
	pause_menu.show()
