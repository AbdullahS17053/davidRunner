extends Node3D
class_name LevelManager

@export var player: Node3D
@export var chunk_scenes: Array[PackedScene]
@export var chunk_length: float = 50.0
@export var chunks_ahead: int = 4
@export var despawn_distance: float = 25.0

var active_chunks: Array[Node3D] = []
var next_spawn_z: float = 0.0

func _ready() -> void:
	assert(chunk_scenes.size() > 0, "LevelManager needs at least one chunk scene to spawn.")
	assert(player != null, "LevelManager needs a reference to the player.")
	
	for i in range(chunks_ahead):
		spawn_chunk()

func _process(_delta: float) -> void:
	if not player or active_chunks.is_empty():
		return
		
	var oldest_chunk: Node3D = active_chunks[0]
	
	if player.global_position.z < oldest_chunk.global_position.z - despawn_distance:
		recycle_chunk()

func spawn_chunk() -> void:
	var random_index: int = randi() % chunk_scenes.size()
	var chunk_instance: Node3D = chunk_scenes[random_index].instantiate()
	
	add_child(chunk_instance)
	chunk_instance.global_position = Vector3(0, 0, next_spawn_z)
	
	active_chunks.append(chunk_instance)
	
	next_spawn_z -= chunk_length

func recycle_chunk() -> void:
	var old_chunk: Node3D = active_chunks.pop_front()
	old_chunk.queue_free()
	
	spawn_chunk()
