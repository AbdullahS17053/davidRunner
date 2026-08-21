extends Node3D
class_name LevelManager

@export var player: Player
@export var base_chunk: PackedScene
@export var chunks_data: Array[ChunkData] 
@export var chunks_ahead: int = 4
@export var despawn_distance: float = 25.0

var active_chunks: Array[Node3D] = []
var next_spawn_z: float = 0.0
var last_chunk_index: int = -1

func _ready() -> void:
	assert(base_chunk != null, "LevelManager needs a base chunk to start with.")
	assert(chunks_data.size() > 0, "LevelManager needs random chunks.")
	assert(player != null, "LevelManager needs a reference to the player.")
	
	spawn_specific_chunk(base_chunk)
	
	for i in range(chunks_ahead - 1):
		spawn_random_chunk()

func _physics_process(delta: float) -> void:
	if not Global.is_game_started: return
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

func spawn_specific_chunk(scene: PackedScene) -> void:
	if scene == null: return
	var chunk_instance: Node3D = scene.instantiate()
	
	add_child(chunk_instance)
	chunk_instance.global_position = Vector3(0, 0, next_spawn_z)
	
	active_chunks.append(chunk_instance)
	
	var end_point: Node3D = chunk_instance.get_node_or_null("EndPoint")
	if end_point:
		next_spawn_z = end_point.global_position.z
	else:
		next_spawn_z -= 50.0

func spawn_random_chunk() -> void:
	if chunks_data.size() <= 1:
		spawn_specific_chunk(chunks_data[0].chunk_scene)
		return

	var total_weight: float = 0.0
	var valid_indices: Array[int] = []
	
	for i in range(chunks_data.size()):
		if i != last_chunk_index and chunks_data[i] != null and chunks_data[i].chunk_scene != null:
			total_weight += chunks_data[i].weight
			valid_indices.append(i)
			
	var random_roll: float = randf_range(0.0, total_weight)
	var chosen_index: int = -1
	
	var current_weight_sum: float = 0.0
	for i in valid_indices:
		current_weight_sum += chunks_data[i].weight
		if random_roll <= current_weight_sum:
			chosen_index = i
			break
			
	if chosen_index == -1:
		chosen_index = valid_indices.back()
		
	last_chunk_index = chosen_index
	spawn_specific_chunk(chunks_data[chosen_index].chunk_scene)

func recycle_chunk() -> void:
	var old_chunk: Node3D = active_chunks.pop_front()
	old_chunk.queue_free()
	
	spawn_random_chunk()
