extends Control
class_name BossBattleUI

@export var progress_bar: ProgressBar
@export var tap_zone: Control
@export var drain_rate: float = 25.0
@export var tap_power: float = 6.0
@export var player: Player

@export var min_zone_scale: float = 0.4
@export var max_zone_scale: float = 1.2

var is_active: bool = false
var tap_tween: Tween

func _ready() -> void:
	self.visible = false
	progress_bar.value = 50.0
	tap_zone.gui_input.connect(_on_tap_zone_gui_input)
	tap_zone.pivot_offset = tap_zone.size / 2.0

func start_boss_fight() -> void:
	self.visible = true
	is_active = true
	progress_bar.value = 50.0
	Global.is_game_started = false
	get_tree().call_group("wolf", "stop_moving")
	
	if player:
		player.move_speed = 0.0
		player.game_start = false
		player.reset_for_boss()

func _process(delta: float) -> void:
	if not is_active:
		return
		
	progress_bar.value -= drain_rate * delta
	
	var current_scale = lerp(min_zone_scale, max_zone_scale, progress_bar.value / 100.0)
	
	if not tap_tween or not tap_tween.is_valid():
		tap_zone.scale = Vector2(current_scale, current_scale)
	
	if progress_bar.value <= 0:
		end_fight(false)
	elif progress_bar.value >= 90:
		end_fight(true)

func _on_tap_zone_gui_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event is InputEventScreenTouch and event.pressed:
		progress_bar.value += tap_power
		Global.on_boss_hit.emit()
		AudioManager.ui_tap.play()
		_animate_tap()

func _animate_tap() -> void:
	if tap_tween and tap_tween.is_valid():
		tap_tween.kill()
		
	var target_scale = lerp(min_zone_scale, max_zone_scale, progress_bar.value / 100.0)
	
	tap_zone.scale = Vector2(target_scale + 0.15, target_scale + 0.15)
	
	tap_tween = create_tween()
	tap_tween.tween_property(tap_zone, "scale", Vector2(target_scale, target_scale), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func end_fight(won: bool) -> void:
	if not is_active:
		return
		
	is_active = false
	self.visible = false
	
	if won:
		Global.boss_defeated.emit()
	else:
		var boss = get_tree().get_first_node_in_group("boss")
		if boss and boss.has_method("force_charge_attack"):
			boss.force_charge_attack()
		else:
			Global.boss_failed.emit()
