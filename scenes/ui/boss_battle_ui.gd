extends Control
class_name BossBattleUI

@export var tap_zone: Control
@export var shrink_time: float = 2.0 # How long the player has to click
@export var player: Player

var is_active: bool = false
var shrink_tween: Tween

func _ready() -> void:
	self.visible = false
	tap_zone.gui_input.connect(_on_tap_zone_gui_input)
	# Ensure it shrinks perfectly into its own center point
	tap_zone.pivot_offset = tap_zone.size / 2.0

func start_boss_fight() -> void:
	self.visible = true
	is_active = true
	Global.is_game_started = false
	get_tree().call_group("wolf", "stop_moving")

	if player:
		player.move_speed = 0.0
		player.game_start = false
		if player.has_method("reset_for_boss"):
			player.reset_for_boss()

	# Reset the tap zone to full size when the fight starts
	tap_zone.scale = Vector2(1.0, 1.0)

	# Start the shrinking timer
	shrink_tween = create_tween()
	shrink_tween.tween_property(tap_zone, "scale", Vector2.ZERO, shrink_time)
	shrink_tween.finished.connect(_on_time_out)

func _on_tap_zone_gui_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	if event is InputEventScreenTouch and event.pressed:
		if AudioManager.has_method("ui_tap"):
			AudioManager.ui_tap.play()
		end_fight(true) # A single successful tap wins the game

func _on_time_out() -> void:
	if is_active:
		end_fight(false) # The zone shrank to 0, player loses

func end_fight(won: bool) -> void:
	if not is_active:
		return
		
	is_active = false
	self.visible = false
	
	if shrink_tween and shrink_tween.is_valid():
		shrink_tween.kill()
		
	if won:
		Global.boss_defeated.emit()
	else:
		var boss = get_tree().get_first_node_in_group("boss")
		if boss and boss.has_method("play_attack"):
			boss.play_attack()
		await get_tree().create_timer(0.5).timeout
		Global.boss_failed.emit()
