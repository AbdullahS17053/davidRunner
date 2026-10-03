extends Control
class_name BossBattleUI

@export var player: Player
@export var tap_zone: Control
@export var world_anims: AnimationPlayer
@export var progress_bar: TextureProgressBar

@export_group("Boss Fight Settings")
@export var enable_tap_fight: bool = true
@export var drain_rate: float = 25.0
@export var tap_power: float = 8.0
@export var completion_value: float = 95.0
@export var min_zone_scale: float = 0.8
@export var max_zone_scale: float = 1.2

var is_active: bool = false
var tap_tween: Tween

func _ready() -> void:
	self.visible = false
	tap_zone.gui_input.connect(_on_tap_zone_gui_input)
	tap_zone.pivot_offset = tap_zone.size / 2.0

func start_boss_fight() -> void:
	if enable_tap_fight:
		self.visible = true
		is_active = true
		progress_bar.value = 50.0
	else:
		self.visible = false
		is_active = false
		_play_auto_cutscene()

func _play_auto_cutscene() -> void:
	await get_tree().create_timer(1.5).timeout
	
	var boss: Boss = get_tree().get_first_node_in_group("boss") as Boss
	if boss:
		player.shoot_at_target(boss)
		
	await get_tree().create_timer(1.0).timeout
	
	end_fight(true)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	progress_bar.value -= drain_rate * delta
	
	var current_scale = lerp(min_zone_scale, max_zone_scale, progress_bar.value / 100.0)
	
	if not tap_tween or not tap_tween.is_valid():
		tap_zone.scale = Vector2(current_scale, current_scale)
		
	if progress_bar.value <= 0:
		end_fight(false)
	elif progress_bar.value >= completion_value:
		end_fight(true)

func _on_tap_zone_gui_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event is InputEventScreenTouch and event.pressed:
		progress_bar.value += tap_power
		AudioManager.ui_tap.play()
		_animate_tap()
		
		var boss: Boss = get_tree().get_first_node_in_group("boss") as Boss
		if boss:
			player.shoot_at_target(boss)

func _animate_tap() -> void:
	if tap_tween and tap_tween.is_valid():
		tap_tween.kill()
		
	var target_scale = lerp(min_zone_scale, max_zone_scale, progress_bar.value / 100.0)
	tap_zone.scale = Vector2(target_scale + 0.15, target_scale + 0.15)
	
	tap_tween = create_tween()
	tap_tween.tween_property(tap_zone, "scale", Vector2(target_scale, target_scale), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func end_fight(won: bool) -> void:
	is_active = false
	self.visible = false
	Global.can_spawn_chunks = true
	
	var boss: Boss = get_tree().get_first_node_in_group("boss") as Boss
	
	if won:
		if boss:
			boss.vulnerable = true
			boss.die()
	else:
		if boss and boss.has_method("play_attack"):
			boss.play_attack()
		await get_tree().create_timer(0.5).timeout
		Global.boss_failed.emit()
