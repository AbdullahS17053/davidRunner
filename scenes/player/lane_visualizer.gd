@tool
extends Node3D

@export var show_lanes: bool = true :
	set(value):
		show_lanes = value
		update_visuals()

@export var lane_width: float = 2.5 :
	set(value):
		lane_width = value
		update_visuals()

@export var lane_length: float = 100.0 :
	set(value):
		lane_length = value
		update_visuals()

@export var lane_color: Color = Color(0.2, 0.8, 0.4, 0.3) :
	set(value):
		lane_color = value
		update_visuals()

var lane_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	update_visuals()

func update_visuals() -> void:
	for mesh in lane_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	lane_meshes.clear()

	if not show_lanes:
		return

	var mat = StandardMaterial3D.new()
	mat.albedo_color = lane_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in range(-1, 2):
		var mesh_inst = MeshInstance3D.new()
		var plane_mesh = PlaneMesh.new()
		
		plane_mesh.size = Vector2(lane_width * 0.9, lane_length)
		
		mesh_inst.mesh = plane_mesh
		mesh_inst.material_override = mat
		
		mesh_inst.position = Vector3(i * lane_width, 0.01, -lane_length / 2.0)
		
		add_child(mesh_inst)
		lane_meshes.append(mesh_inst)
