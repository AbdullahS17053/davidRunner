extends HBoxContainer
class_name FloatingText2D

@export var float_distance: float = 80.0
@export var duration: float = 0.6

@export var floating_text: Label

func setup_and_play(amount: int, start_pos: Vector2) -> void:
	floating_text.text = "+ " + str(amount)
	position = start_pos - (size / 2.0)
	
	var tween: Tween = create_tween()
	
	tween.tween_property(self, "position:y", position.y - float_distance, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
