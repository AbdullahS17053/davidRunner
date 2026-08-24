class_name MapSelectUI
extends Control

@export var available_maps: Array[MapData]

@export var map_image: TextureRect
@export var map_select_anims: AnimationPlayer
@export var world_environment: WorldEnvironment

var current_preview_index: int = 0

func _ready() -> void:
	current_preview_index = Global.selected_map_index
	update_display()

func update_display() -> void:
	if available_maps.is_empty(): 
		return
		
	var map: MapData = available_maps[current_preview_index]
	#header_label.text = map.map_name
	map_image.texture = map.map_image

func _on_select_btn_pressed() -> void:
	AudioManager.ui_click.play()
	
	Global.selected_map_index = current_preview_index
	get_tree().reload_current_scene()

func _on_button_left_pressed() -> void:
	AudioManager.ui_click.play()
	
	current_preview_index -= 1
	if current_preview_index < 0:
		current_preview_index = available_maps.size() - 1
		
	update_display()

func _on_button_right_pressed() -> void:
	AudioManager.ui_click.play()
	
	current_preview_index += 1
	if current_preview_index >= available_maps.size():
		current_preview_index = 0
		
	update_display()

func _on_close_btn_pressed() -> void:
	AudioManager.ui_click.play()
	map_select_anims.play("exit")
