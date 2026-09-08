extends Node3D

@export var min_curve_x: float = -0.008
@export var max_curve_x: float = 0.008
@export var curve_y: float = -0.01
@export var min_sway_time: float = 4.0
@export var max_sway_time: float = 8.0

var current_curve_x: float = 0.0

func _ready() -> void:
	start_random_sway()

func start_random_sway() -> void:
	#if not Global.is_game_started: return
	var target_x: float = randf_range(min_curve_x, max_curve_x)
	var sway_duration: float = randf_range(min_sway_time, max_sway_time)
	
	var tween: Tween = create_tween()
	
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(update_shader_curve, current_curve_x, target_x, sway_duration)
	tween.tween_callback(start_random_sway)

func update_shader_curve(new_x: float) -> void:
	#if not Global.is_game_started: return
	current_curve_x = new_x
	
	var new_intensity = Vector2(current_curve_x, curve_y)
	RenderingServer.global_shader_parameter_set("global_curve_intensity", new_intensity)
