extends Control
class_name GameUI

@export var coins_label: Label
@export var distance_label: Label
@export var pause_menu: PauseMenu
@export var boss_ui: BossBattleUI
@export var warning_label: Label
@export var warning_duration: float = 3.0

@export var player: Player
@export var boss_scene: PackedScene
@export var boss_trigger_time: float = 120.0

var current_boss: Boss
var time_played: float = 0.0
var boss_fought: bool = false

var is_waiting_for_clearance: bool = false
var is_warning_phase: bool = false
var warning_timer: float = 0.0
var warning_tween: Tween

func _ready() -> void:
	Global.coin_collected.connect(on_coin_collected)
	
	Global.boss_failed.connect(_on_boss_failed)
	Global.boss_defeated.connect(_on_boss_defeated)

func _process(delta: float) -> void:
	if not Global.is_game_started: return
	
	Global.distance += 0.2 * delta
	distance_label.text = "%.2f km" % Global.distance
	
	if not boss_fought and not is_warning_phase and not is_waiting_for_clearance:
		time_played += delta
		if time_played >= boss_trigger_time:
			is_warning_phase = true
			_play_warning_effect()
			
	if is_warning_phase:
		warning_timer += delta
		if warning_timer >= warning_duration:
			is_warning_phase = false
			is_waiting_for_clearance = true
			
	if is_waiting_for_clearance:
		if _is_path_clear():
			is_waiting_for_clearance = false
			boss_fought = true
			
			if warning_label:
				warning_label.visible = false 
			if warning_tween and warning_tween.is_valid():
				warning_tween.kill()
				
			_trigger_boss_encounter()

func _trigger_boss_encounter() -> void:
	if boss_scene and player:
		current_boss = boss_scene.instantiate() as Boss
		get_tree().current_scene.add_child(current_boss)
		current_boss.spawn_from_sky(player)
		
		var timer: SceneTreeTimer = get_tree().create_timer(current_boss.fall_duration)
		timer.timeout.connect(func():
			boss_ui.start_boss_fight()
		)

func _is_path_clear() -> bool:
	if not player: 
		return false
		
	var obstacles = get_tree().get_nodes_in_group("obstacle")
	var check_distance: float = 20.0 
	var safe_zone_radius: float = 5.0
	
	for obs in obstacles:
		var is_same_lane: bool = abs(obs.global_position.x - player.global_position.x) < 0.5
		
		if is_same_lane:
			var is_in_front: bool = obs.global_position.z < player.global_position.z
			var is_in_drop_range: bool = obs.global_position.z > (player.global_position.z - check_distance)
			
			var distance_to_player: float = abs(obs.global_position.z - player.global_position.z)
			var is_too_close_to_player: bool = distance_to_player < safe_zone_radius
			
			if (is_in_front and is_in_drop_range) or is_too_close_to_player:
				return false
				
	return true

func _play_warning_effect() -> void:
	if not warning_label:
		return
		
	warning_label.visible = true
	warning_label.modulate.a = 0.0
	
	warning_tween = create_tween().set_loops() 
	warning_tween.tween_property(warning_label, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)
	warning_tween.tween_property(warning_label, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_SINE)
	# AudioManager.play_warning_siren()

func on_coin_collected(amount: int) -> void:
	coins_label.text = "%d" % amount
	print(amount)
	if Global.coins > Global.highest_coins:
		Global.highest_coins = Global.coins
		Global.save_stats()

func _on_pause_btn_pressed() -> void:
	get_tree().paused = true
	AudioManager.ui_click.play()
	pause_menu.pause_anims.play("open", -1, 2.0)

func _on_boss_failed() -> void:
	if current_boss:
		current_boss.play_attack()
	
	await get_tree().create_timer(0.5).timeout
	Global.game_over.emit()

func _on_boss_defeated() -> void:
	if current_boss:
		current_boss.play_defeat()
	Global.coins += 100
	Global.coin_collected.emit(Global.coins)
