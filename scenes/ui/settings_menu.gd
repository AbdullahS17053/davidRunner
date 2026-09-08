extends Control
class_name SettingsMenu

@export_group("UI References")
@export var res_scale_value: Label
@export var shadows_toggle: CheckBox 
@export var fps_toggle: CheckBox
@export var res_scale_slider: Slider
@export var sfx_toggle: CheckBox
@export var music_toggle: CheckBox

@export_group("Game References")
@export var settings_anims: AnimationPlayer
@export var directional_light: DirectionalLight3D

var settings_data: Dictionary = {
}

func _ready() -> void:
	settings_data = SaveManager.data["settings"]
	
	shadows_toggle.button_pressed = settings_data["shadows_on"]
	if directional_light: directional_light.shadow_enabled = settings_data["shadows_on"]
	
	fps_toggle.button_pressed = settings_data["fps_on"]
	DebugMenu.visible = settings_data["fps_on"]
	
	res_scale_slider.value = settings_data["res_scale"]
	res_scale_value.text = "%.2f" % settings_data["res_scale"] 
	
	var sfx_bus_index: int = AudioServer.get_bus_index("SFX")
	sfx_toggle.button_pressed = settings_data["sfx_on"]
	AudioServer.set_bus_mute(sfx_bus_index, not settings_data["sfx_on"])
	
	var music_bus_index: int = AudioServer.get_bus_index("Music")
	music_toggle.button_pressed = settings_data["music_on"]
	AudioServer.set_bus_mute(music_bus_index, not settings_data["music_on"])

func _on_close_btn_pressed() -> void:
	AudioManager.ui_click.play()
	settings_anims.play("exit")
	SaveManager.data["settings"] = settings_data
	SaveManager.save_game()

func _on_shadows_toggle_toggled(toggled_on: bool) -> void:
	settings_data["shadows_on"] = toggled_on
	if directional_light:
		directional_light.shadow_enabled = toggled_on

func _on_fps_toggle_toggled(toggled_on: bool) -> void:
	settings_data["fps_on"] = toggled_on
	DebugMenu.visible = toggled_on

func _on_res_scale_slider_value_changed(value: float) -> void:
	settings_data["res_scale"] = value
	res_scale_value.text = "%.2f" % value 
	get_viewport().scaling_3d_scale = value

func _on_sound_fx_check_box_toggled(toggled_on: bool) -> void:
	settings_data["sfx_on"] = toggled_on
	var bus_index: int = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(bus_index, not toggled_on)

func _on_music_checkbox_toggled(toggled_on: bool) -> void:
	settings_data["music_on"] = toggled_on
	var bus_index: int = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_mute(bus_index, not toggled_on)
