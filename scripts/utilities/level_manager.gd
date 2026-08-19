extends Node3D
class_name LevelManager

@export var player: Node3D
@export var base_chunk: PackedScene
@export var chunk_scenes: Array[PackedScene]
@export var chunk_length: float = 50.0
@export var chunks_ahead: int = 4
@export var despawn_distance: float = 25.0

var active_chunks: Array[Node3D] = []
var next_spawn_z: float = 0.0

func _ready() -> void:
	assert(base_chunk != null, "LevelManager needs a base chunk to start with.")
	assert(chunk_scenes.size() > 0, "LevelManager needs at least one random chunk scene to spawn.")
	assert(player != null, "LevelManager needs a reference to the player.")
	
	spawn_specific_chunk(base_chunk)
	
	for i in range(chunks_ahead - 1):
		spawn_random_chunk()

func _process(_delta: float) -> void:
	if not player or active_chunks.is_empty():
		return
		
	var oldest_chunk: Node3D = active_chunks[0]
	
	if player.global_position.z < oldest_chunk.global_position.z - despawn_distance:
		recycle_chunk()

func spawn_specific_chunk(scene: PackedScene) -> void:
	var chunk_instance: Node3D = scene.instantiate()
	
	add_child(chunk_instance)
	chunk_instance.global_position = Vector3(0, 0, next_spawn_z)
	
	active_chunks.append(chunk_instance)
	
	next_spawn_z -= chunk_length

func spawn_random_chunk() -> void:
	var random_index: int = randi() % chunk_scenes.size()
	spawn_specific_chunk(chunk_scenes[random_index])

func recycle_chunk() -> void:
	var old_chunk: Node3D = active_chunks.pop_front()
	old_chunk.queue_free()
	
	spawn_random_chunk()
