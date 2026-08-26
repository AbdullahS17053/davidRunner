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
@export_custom(PROPERTY_HINT_NONE, "suffix:Seconds") var boss_trigger_time: float = 120.0

var current_boss: Boss
var time_played: float = 0.0
var boss_fought: bool = false

var is_waiting_for_clearance: bool = false
var is_warning_phase: bool = false
var warning_timer: float = 0.0
var warning_tween: Tween

var world_end_z: float = 0.0

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
			Global.can_spawn_chunks = false # STOP SPAWNING CHUNKS NOW!
			
	if is_waiting_for_clearance:
		if _is_at_world_end(): 
			is_waiting_for_clearance = false
			boss_fought = true
			
			if warning_label:
				warning_label.visible = false 
			if warning_tween and warning_tween.is_valid():
				warning_tween.kill()
				
			_trigger_boss_encounter()

func _trigger_boss_encounter() -> void:
	if boss_scene and player:
		Global.is_game_started = false
		get_tree().call_group("wolf", "stop_moving")
		
		if player:
			player.move_speed = 0.0
			if player.has_method("reset_for_boss"):
				player.reset_for_boss()
		
		current_boss = boss_scene.instantiate() as Boss
		get_tree().current_scene.add_child(current_boss)
		
		current_boss.rise_from_abyss(player, world_end_z)
		
		var timer: SceneTreeTimer = get_tree().create_timer(current_boss.rise_duration)
		timer.timeout.connect(func():
			boss_ui.start_boss_fight()
		)

func _is_at_world_end() -> bool:
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if not level_manager or level_manager.active_chunks.is_empty():
		return true # Failsafe
		
	var last_chunk = level_manager.active_chunks.back()
	var end_point = last_chunk.get_node_or_null("EndPoint")
	
	var end_z: float = last_chunk.global_position.z - 50.0
	if end_point:
		end_z = end_point.global_position.z
		
	var distance_to_end = abs(player.global_position.z - end_z)
	
	if distance_to_end <= 10.0:
		world_end_z = end_z
		return true
		
	return false

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
	AudioManager.bgm.stream_paused = true
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
