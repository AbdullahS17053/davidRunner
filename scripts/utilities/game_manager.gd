extends Node

@export var player: Player
@export var total_coins_label: Label
@export var main_menu: MainMenu
@export var world_anims: AnimationPlayer

func _unhandled_input(event: InputEvent) -> void:
	if Global.is_game_started: return
	
	if not player.is_dead:
		if event is InputEventScreenTouch:
			if event.pressed and event.position:
				if main_menu: main_menu.menu_anims.play("exit")
				start_gameplay()
		elif event is InputEventKey:
			if event.pressed and event.keycode == KEY_SPACE:
				if main_menu: main_menu.menu_anims.play("exit")
				start_gameplay()

func _ready() -> void:
	if Global.auto_restart:
		Global.auto_restart = false
		start_gameplay()
		if main_menu: main_menu.hide()

func _process(_delta: float) -> void:
	total_coins_label.text = "%d" % Global.total_coins

func start_gameplay() -> void:
	player.dust_particles.show()
	world_anims.play("Intro")
	Global.is_game_started = true
	AudioManager.bgm.play()
