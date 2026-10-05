class_name Player
extends CharacterBody3D

@export var move_speed: float = 12.0
@export var jump_force: float = 8.0

@export_group("Touch Controls")
@export var swipe_threshold: float = 50.0

@export_group("Difficulty Settings")
@export var max_speed: float = 40.0
@export var acceleration: float = 0.1

@export_group("Lane Settings")
@export var lane_width: float = 2.5
@export var switch_speed: float = 15.0

@export_group("Slide Settings")
@export var slide_duration: float = 0.8
@export var fast_fall_force: float = 15.0

@export_group("References")
@export var default_skin: SkinsData
@export var col_shape: CollisionShape3D
@export var animation_tree: AnimationTree
@export var animation_playback: AnimationNodeStateMachinePlayback
@export var dust_particles: GPUParticles3D
@export var slide_particles: GPUParticles3D
@export var revive_particles: GPUParticles3D
@export var player_anims: AnimationPlayer
@export var heavy_shake: ShakerComponent3D
@export var shaker_component_3d: ShakerComponent3D

@export var visuals_node: Node3D

@export_subgroup("Projectile")
@export var projectile_scene: PackedScene
@export var projectile_spawn_point: Marker3D

var current_skin_node: Node3D

var is_swiping: bool = false
var touch_start_pos: Vector2 = Vector2.ZERO

var current_lane: int = 0
var is_sliding: bool = false
var slide_timer: float = 0.0

var is_jumping: bool = false
var is_switching_left: bool = false
var is_switching_right: bool = false

var normal_height: float
var normal_pos_y: float

var is_dead: bool = false
var is_invincible: bool = false
var has_shield: bool = false
var has_slingshot: bool = false
var slingshot_timer: float = 0.0
var has_coin_magnet: bool = false
var magnet_timer: float = 0.0
var has_double_coins: bool = false
var double_coins_timer: float = 0.0
var speed_boost_level: int = 0
var has_heavenly_lift: bool = false
var heavenly_lift_timer: float = 0.0
var sky_items: Array[Node3D] = []
var sky_spawn_timer: float = 0.0

var collectible_scene = preload("res://scenes/collectibles/collectible.tscn")
var powerup_scene = preload("res://scenes/collectibles/powerup.tscn")

var game_start: bool = false
var is_shooting: bool = false

func _ready() -> void:
	Global.player_revived.connect(_on_player_revived)
	is_dead = false
	is_invincible = false
	has_shield = false
	global_position.x = 0.0
	
	col_shape.shape = col_shape.shape.duplicate()
	
	normal_height = col_shape.shape.height
	normal_pos_y = col_shape.position.y
	
	var saved_skin_path: String = SaveManager.data["skins"]["equipped_skin_path"]
	
	if saved_skin_path != "" and ResourceLoader.exists(saved_skin_path):
		Global.equipped_skin = load(saved_skin_path) as SkinsData
	else:
		Global.equipped_skin = default_skin
		if Global.equipped_skin:
			Global.equipped_skin.skin_unlocked = true
			SaveManager.data["skins"]["equipped_skin_path"] = Global.equipped_skin.resource_path
			
			if not Global.equipped_skin.resource_path in SaveManager.data["skins"]["unlocked_skin_paths"]:
				SaveManager.data["skins"]["unlocked_skin_paths"].append(Global.equipped_skin.resource_path)
			
			SaveManager.save_game()
			
	apply_equipped_skin()

func _input(event: InputEvent) -> void:
	if not Global.is_game_started: return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			is_swiping = true
			touch_start_pos = event.position
		else:
			is_swiping = false
			
	elif event is InputEventScreenDrag and is_swiping:
		var swipe_dir: Vector2 = event.position - touch_start_pos
		
		if swipe_dir.length() >= swipe_threshold:
			is_swiping = false
			
			if abs(swipe_dir.x) > abs(swipe_dir.y):
				if swipe_dir.x > 0:
					simulate_input("right")
				else:
					simulate_input("left")
			else:
				if swipe_dir.y > 0:
					simulate_input("slide")
				else:
					simulate_input("jump")

func _physics_process(delta: float) -> void:
	if not Global.is_game_started: return
	
	game_start = Global.is_game_started
	
	if move_speed < max_speed:
		move_speed += acceleration * delta
		move_speed = min(move_speed, max_speed)
	
	if not is_on_floor():
		dust_particles.emitting = false
		velocity += get_gravity() * delta * 2.0
		
		if Input.is_action_just_pressed("slide"):
			is_jumping = false
			velocity.y = - fast_fall_force
	else:
		is_jumping = false
		dust_particles.emitting = true
		
		if Input.is_action_just_pressed("jump"):
			is_jumping = true
			velocity.y = jump_force
			stop_slide()
			
		if Input.is_action_just_pressed("slide") and not is_sliding:
			is_jumping = false
			start_slide()

	if has_heavenly_lift:
		velocity.y = (15.0 - global_position.y) * 1.5

	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			stop_slide()

	velocity.z = 0.0
	
	is_switching_left = Input.is_action_just_pressed("left")
	is_switching_right = Input.is_action_just_pressed("right")
	
	if is_switching_left:
		current_lane = max(current_lane - 1, -1)
	elif is_switching_right:
		current_lane = min(current_lane + 1, 1)

	var target_x: float = current_lane * lane_width
	var dynamic_switch = switch_speed * (move_speed / 12.0)
	var new_x: float = lerpf(global_position.x, target_x, dynamic_switch * delta)
	velocity.x = (new_x - global_position.x) / delta
	
	_handle_powerups(delta)
	
	move_and_slide()

func _handle_powerups(delta: float) -> void:
	if has_slingshot:
		slingshot_timer -= delta
		if slingshot_timer <= 0:
			has_slingshot = false
			print("Slingshot powerup ended.")
		elif not is_shooting:
			var wolves = get_tree().get_nodes_in_group("wolf")
			for wolf in wolves:
				if not wolf.is_dead and wolf.global_position.distance_to(global_position) < 20.0 and wolf.global_position.z < global_position.z:
					shoot_at_target(wolf)
					break

	if has_coin_magnet:
		magnet_timer -= delta
		if magnet_timer <= 0:
			has_coin_magnet = false
			print("Coin Magnet powerup ended.")
		else:
			var coins = get_tree().get_nodes_in_group("coin")
			for coin in coins:
				if not coin.is_magnetized and coin.global_position.distance_to(global_position) < 8.0:
					coin.is_magnetized = true
					coin.target_player = self

	if has_double_coins:
		double_coins_timer -= delta
		if double_coins_timer <= 0:
			has_double_coins = false
			print("Double Coins powerup ended.")

	if has_heavenly_lift:
		heavenly_lift_timer -= delta
		if heavenly_lift_timer <= 0:
			has_heavenly_lift = false
			_grant_invincibility(3.0)
			print("Heavenly Lift ended. Granted temporary invincibility.")
		else:
			sky_spawn_timer -= delta
			if sky_spawn_timer <= 0:
				sky_spawn_timer = 0.2
				_spawn_sky_item()
				
	for i in range(sky_items.size() - 1, -1, -1):
		var item = sky_items[i]
		if is_instance_valid(item):
			item.global_position.z += move_speed * delta
			if item.global_position.z > global_position.z + 10.0:
				item.queue_free()
				sky_items.remove_at(i)
		else:
			sky_items.remove_at(i)

func _spawn_sky_item() -> void:
	var item: Node3D
	if randf() < 0.05:
		item = powerup_scene.instantiate()
	else:
		item = collectible_scene.instantiate()
		
	var random_lane = randi_range(-1, 1)
	item.position = Vector3(random_lane * lane_width, 16.0, global_position.z - 40.0)
	
	get_parent().add_child(item)
	sky_items.append(item)

func start_slide() -> void:
	is_sliding = true
	slide_timer = slide_duration
	
	col_shape.shape.height = normal_height / 2.0
	col_shape.position.y = normal_pos_y - (normal_height / 4.0)

func stop_slide() -> void:
	if not is_sliding: return
	is_sliding = false
	
	col_shape.shape.height = normal_height
	col_shape.position.y = normal_pos_y

func simulate_input(action_name: String) -> void:
	var press_event = InputEventAction.new()
	press_event.action = action_name
	press_event.pressed = true
	Input.parse_input_event(press_event)
	
	var release_event = InputEventAction.new()
	release_event.action = action_name
	release_event.pressed = false
	Input.parse_input_event(release_event)

func reset_for_boss() -> void:
	game_start = false
	position.y = 0.0
	velocity = Vector3.ZERO
	dust_particles.emitting = false
	slide_particles.emitting = false

	current_lane = 0
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	is_jumping = false
	is_sliding = false

func apply_equipped_skin() -> void:
	if not visuals_node:
		return
		
	if current_skin_node:
		current_skin_node.queue_free()
		
	if Global.equipped_skin and Global.equipped_skin.skin_scene:
		current_skin_node = Global.equipped_skin.skin_scene.instantiate()
		visuals_node.add_child(current_skin_node)
		
		var anim_players = current_skin_node.find_children("*", "AnimationPlayer", true, false)
		if anim_players.size() > 0:
			player_anims = anim_players[0] as AnimationPlayer
			
		var anim_trees = current_skin_node.find_children("*", "AnimationTree", true, false)
		if anim_trees.size() > 0:
			animation_tree = anim_trees[0] as AnimationTree
			
		var markers = current_skin_node.find_children("*ProjectileSpawn*", "Marker3D", true, false)
		if markers.size() > 0:
			projectile_spawn_point = markers[0] as Marker3D

		var skeleton: Skeleton3D = current_skin_node as Skeleton3D
		if not skeleton:
			var skeletons = current_skin_node.find_children("*", "Skeleton3D", true, false)
			if skeletons.size() > 0:
				skeleton = skeletons[0] as Skeleton3D

		if skeleton:
			var target_root = skeleton.get_parent()
			
			if player_anims and not player_anims.is_ancestor_of(skeleton):
				player_anims.root_node = player_anims.get_path_to(target_root)
			
			if animation_tree and not animation_tree.is_ancestor_of(skeleton):
				animation_tree.root_node = animation_tree.get_path_to(target_root)

		if animation_tree:
			animation_tree.advance_expression_base_node = animation_tree.get_path_to(self)
			
			animation_tree.active = false
			animation_tree.active = true
			var playback = animation_tree.get("parameters/playback")
			if playback is AnimationNodeStateMachinePlayback:
				animation_playback = playback

func player_death() -> void:
	is_dead = true
	shaker_component_3d.play_shake()
	Global.is_game_started = false
	dust_particles.emitting = false
	
	if player_anims and player_anims.has_animation("death"):
		player_anims.play("death")
		
	AudioManager.fail.play()
	AudioManager.bgm.stop()
	AudioManager.death_impact.play()
	
	_trigger_ragdoll()
	
	Global.total_coins += Global.coins
	Global.save_stats()

func _on_player_revived() -> void:
	revive_particles.restart()
	Global.total_coins -= Global.coins
	Global.save_stats()
	
	is_dead = false
	Global.is_game_started = true
	dust_particles.emitting = true
	
	_stop_ragdoll()
	
	if animation_playback:
		animation_playback.travel("run")
	elif player_anims and player_anims.has_animation("run"):
		player_anims.play("run")
		
	AudioManager.bgm.play()
	
	_grant_invincibility(3.0)

func _grant_invincibility(duration: float) -> void:
	is_invincible = true
	var blink_count: int = int(duration * 2)
	var blink_time: float = duration / (blink_count * 2.0)
	
	if current_skin_node:
		var materials: Array[BaseMaterial3D] = []
		var meshes = current_skin_node.find_children("*", "MeshInstance3D", true, false)
		
		for mesh_node in meshes:
			var mesh_instance := mesh_node as MeshInstance3D
			if not mesh_instance.mesh:
				continue
				
			for j in range(mesh_instance.mesh.get_surface_count()):
				var mat = mesh_instance.get_surface_override_material(j)
				if not mat:
					mat = mesh_instance.mesh.surface_get_material(j)
					
				if mat and mat is BaseMaterial3D:
					mat = mat.duplicate()
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mesh_instance.set_surface_override_material(j, mat)
					materials.append(mat)
					
		if materials.size() > 0:
			var tween = create_tween()
			tween.set_loops(blink_count)
			
			for i in range(materials.size()):
				if i == 0:
					tween.tween_property(materials[i], "albedo_color:a", 0.3, blink_time)
				else:
					tween.parallel().tween_property(materials[i], "albedo_color:a", 0.3, blink_time)
					
			for i in range(materials.size()):
				if i == 0:
					tween.tween_property(materials[i], "albedo_color:a", 1.0, blink_time)
				else:
					tween.parallel().tween_property(materials[i], "albedo_color:a", 1.0, blink_time)
	
	await get_tree().create_timer(duration).timeout
	is_invincible = false
	
	if current_skin_node:
		var meshes_to_reset = current_skin_node.find_children("*", "MeshInstance3D", true, false)
		for mesh_node in meshes_to_reset:
			var mesh_instance := mesh_node as MeshInstance3D
			if mesh_instance.mesh:
				for j in range(mesh_instance.mesh.get_surface_count()):
					mesh_instance.set_surface_override_material(j, null)


func _stop_ragdoll() -> void:
	if not current_skin_node:
		return
	var simulators = current_skin_node.find_children("*", "PhysicalBoneSimulator3D", true, false)
	if simulators.size() > 0:
		simulators[0].physical_bones_stop_simulation()

func _trigger_ragdoll() -> void:
	if not current_skin_node:
		return
		
	var simulators = current_skin_node.find_children("*", "PhysicalBoneSimulator3D", true, false)
	if simulators.size() > 0:
		simulators[0].physical_bones_start_simulation()

func shoot_at_target(target_node: Node3D) -> void:
	if is_shooting:
		return
		
	is_shooting = true
	
	if animation_tree:
		animation_tree["parameters/slingshot_oneshot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	elif player_anims and player_anims.has_animation("slingshot"):
		player_anims.play("slingshot")
	
	await get_tree().create_timer(0.4).timeout
	
	if not is_inside_tree():
		is_shooting = false
		return
		
	if is_instance_valid(target_node) and projectile_scene and projectile_spawn_point:
		var projectile: Projectile = projectile_scene.instantiate() as Projectile
		get_parent().add_child(projectile)
		
		projectile.global_position = projectile_spawn_point.global_position
		projectile.fire_at(target_node)
		
	await get_tree().create_timer(0.5).timeout
	
	is_shooting = false

func play_slingshot_animation() -> void:
	if animation_tree:
		animation_tree["parameters/slingshot_oneshot/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	elif player_anims and player_anims.has_animation("slingshot"):
		player_anims.play("slingshot")

func _on_collision_body_entered(body: Node3D) -> void:
	if body.is_in_group("obstacle") and not is_invincible:
		if has_shield:
			has_shield = false
			_grant_invincibility(1.5)
			print("Shield broken! Invincible for 1.5 seconds.")
			return
			
		Global.game_over.emit()

func activate_shield() -> void:
	has_shield = true
	print("Shield of Faith activated!")

func apply_powerup(data: PowerupData) -> void:
	if not data: return
	
	match data.type:
		PowerupData.PowerupType.SHIELD:
			activate_shield()
		PowerupData.PowerupType.SLINGSHOT:
			has_slingshot = true
			slingshot_timer = data.duration
			print("Slingshot powerup activated for %s seconds!" % data.duration)
		PowerupData.PowerupType.MAGNET:
			has_coin_magnet = true
			magnet_timer = data.duration
			print("Coin Magnet powerup activated for %s seconds!" % data.duration)
		PowerupData.PowerupType.DOUBLE_COINS:
			has_double_coins = true
			double_coins_timer = data.duration
			print("Double Coins powerup activated for %s seconds!" % data.duration)
		PowerupData.PowerupType.SPEED_BOOST:
			speed_boost_level += 1
			move_speed += 0.5
			if move_speed > max_speed:
				move_speed = max_speed
			print("Speed Boost level up! Current level: %s, New Speed: %s" % [speed_boost_level, move_speed])
		PowerupData.PowerupType.HEAVENLY_LIFT:
			has_heavenly_lift = true
			heavenly_lift_timer = data.duration
			print("Heavenly Lift activated for %s seconds!" % data.duration)
