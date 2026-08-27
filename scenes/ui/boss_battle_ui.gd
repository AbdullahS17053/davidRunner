extends Control
class_name BossBattleUI

@export var tap_zone: Control
@export var shrink_time: float = 2.0
@export var player: Player
@export var world_anims: AnimationPlayer

var is_active: bool = false
var shrink_tween: Tween

func _ready() -> void:
	self.visible = false
	tap_zone.gui_input.connect(_on_tap_zone_gui_input)
	tap_zone.pivot_offset = tap_zone.size / 2.0

func start_boss_fight() -> void:
	self.visible = true
	is_active = true
	
	tap_zone.scale = Vector2(1.0, 1.0)
	
	shrink_tween = create_tween()
	shrink_tween.tween_property(tap_zone, "scale", Vector2.ZERO, shrink_time)
	shrink_tween.finished.connect(_on_time_out)

func _on_tap_zone_gui_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event is InputEventScreenTouch and event.pressed:
		var boss: Boss = get_tree().get_first_node_in_group("boss") as Boss
		if boss:
			player.shoot_at_target(boss.head_point)
			
		AudioManager.ui_tap.play()
		end_fight(true)

func _on_time_out() -> void:
	if is_active:
		end_fight(false)

func end_fight(won: bool) -> void:
	if not is_active:
		return
		
	is_active = false
	self.visible = false
	
	if shrink_tween and shrink_tween.is_valid():
		shrink_tween.kill()
	
	Global.can_spawn_chunks = true
	
	if won: pass
	else:
		var boss: Boss = get_tree().get_first_node_in_group("boss") as Boss
		if boss and boss.has_method("play_attack"):
			boss.play_attack()
		await get_tree().create_timer(0.5).timeout
		Global.boss_failed.emit()
