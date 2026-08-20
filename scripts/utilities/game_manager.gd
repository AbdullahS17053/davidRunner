extends Node

func _ready() -> void:
	if OS.has_feature("mobile"):
		Engine.max_fps = 60
	else:
		Engine.max_fps = 60
