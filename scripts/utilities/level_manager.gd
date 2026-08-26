extends Node3D
class_name LevelManager

@export var player: Player
@export var available_maps: Array[MapData]
@export var chunks_ahead: int = 4
@export var despawn_distance: float = 25.0

@export var world_environment: WorldEnvironment

var active_base_chunk: PackedScene
var active_chunks_data: Array[ChunkData]
var active_end_chunk: PackedScene

var active_chunks: Array[Node3D] = []
var next_spawn_z: float = 0.0
var last_chunk_index: int = -1
var pending_tasks: Dictionary = {}

var has_spawned_end_chunk: bool = false

func _ready() -> void:
	has_spawned_end_chunk = false
	
	var current_map: MapData = available_maps[Global.selected_map_index]
	active_base_chunk = current_map.base_chunk
	active_chunks_data = current_map.chunks_data
	
	active_end_chunk = current_map.world_end_chunk 
	
	if world_environment and current_map.map_env:
		world_environment.environment = current_map.map_env
		
	assert(active_base_chunk != null, "LevelManager needs a base chunk to start with.")
	assert(active_chunks_data.size() > 0, "LevelManager needs random chunks.")
	assert(player != null, "LevelManager needs a reference to the player.")
	
	spawn_specific_chunk_sync(active_base_chunk)
	for i in range(chunks_ahead - 1):
		spawn_random_chunk_sync()

func _physics_process(delta: float) -> void:
	if not Global.is_game_started: return
	
	_check_pending_tasks()
	
	if not player or active_chunks.is_empty():
		return
		
	var current_speed: float = player.move_speed
	
	for chunk in active_chunks:
		chunk.global_position.z += current_speed * delta
		
	next_spawn_z += current_speed * delta
	
	var oldest_chunk: Node3D = active_chunks[0]
	var end_point: Node3D = oldest_chunk.get_node_or_null("EndPoint")
	
	var chunk_end_z: float = oldest_chunk.global_position.z
	if end_point:
		chunk_end_z = end_point.global_position.z
	else:
		chunk_end_z -= 50.0
		
	if chunk_end_z > player.global_position.z + despawn_distance:
		recycle_chunk()

func _check_pending_tasks() -> void:
	var completed_tasks: Array[int] = []
	
	for task_id in pending_tasks.keys():
		if WorkerThreadPool.is_task_completed(task_id):
			WorkerThreadPool.wait_for_task_completion(task_id)
			
			var result_container: Array = pending_tasks[task_id]
			var chunk_instance: Node3D = result_container[0]
			
			_finalize_chunk(chunk_instance)
			completed_tasks.append(task_id)
			
	for task_id in completed_tasks:
		pending_tasks.erase(task_id)

func _thread_instantiate(scene: PackedScene, result_container: Array) -> void:
	result_container.append(scene.instantiate())

func spawn_random_chunk_async() -> void:
	if not Global.can_spawn_chunks:
		if not has_spawned_end_chunk and active_end_chunk != null:
			has_spawned_end_chunk = true
			
			var result_container: Array = []
			var callable = _thread_instantiate.bind(active_end_chunk, result_container)
			var task_id = WorkerThreadPool.add_task(callable, true, "Instantiate End Chunk")
			pending_tasks[task_id] = result_container
		return
		
	var scene: PackedScene = _get_random_chunk_scene()
	if scene == null: return
	
	var result_container: Array = []
	var callable = _thread_instantiate.bind(scene, result_container)
	var task_id = WorkerThreadPool.add_task(callable, true, "Instantiate Chunk")
	pending_tasks[task_id] = result_container

func spawn_specific_chunk_sync(scene: PackedScene) -> void:
	if not Global.can_spawn_chunks:
		return

	if scene == null: return
	var chunk_instance: Node3D = scene.instantiate()
	_finalize_chunk(chunk_instance)

func spawn_random_chunk_sync() -> void:
	if not Global.can_spawn_chunks:
		if not has_spawned_end_chunk and active_end_chunk != null:
			has_spawned_end_chunk = true
			spawn_specific_chunk_sync(active_end_chunk)
		return
		
	var scene: PackedScene = _get_random_chunk_scene()
	spawn_specific_chunk_sync(scene)

func _finalize_chunk(chunk_instance: Node3D) -> void:
	add_child(chunk_instance)
	chunk_instance.global_position = Vector3(0, 0, next_spawn_z)
	
	active_chunks.append(chunk_instance)
	
	var end_point: Node3D = chunk_instance.get_node_or_null("EndPoint")
	if end_point:
		next_spawn_z = end_point.global_position.z
	else:
		next_spawn_z -= 50.0

func recycle_chunk() -> void:
	var old_chunk: Node3D = active_chunks.pop_front()
	old_chunk.queue_free()
	spawn_random_chunk_async()

func _get_random_chunk_scene() -> PackedScene:
	if active_chunks_data.size() <= 1:
		return active_chunks_data[0].chunk_scene

	var total_weight: float = 0.0
	var valid_indices: Array[int] = []
	
	for i in range(active_chunks_data.size()):
		if i != last_chunk_index and active_chunks_data[i] != null and active_chunks_data[i].chunk_scene != null:
			total_weight += active_chunks_data[i].weight
			valid_indices.append(i)
			
	var random_roll: float = randf_range(0.0, total_weight)
	var chosen_index: int = -1
	
	var current_weight_sum: float = 0.0
	for i in valid_indices:
		current_weight_sum += active_chunks_data[i].weight
		if random_roll <= current_weight_sum:
			chosen_index = i
			break
			
	if chosen_index == -1:
		chosen_index = valid_indices.back()
		
	last_chunk_index = chosen_index
	return active_chunks_data[chosen_index].chunk_scene
