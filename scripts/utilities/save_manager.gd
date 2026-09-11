extends Node

const SAVE_PATH = "user://save_data.json"

var data: Dictionary = {
	"stats": {
		"total_coins": 0,
		"high_score": 0
	},
	"settings": {
		"shadows_on": true,
		"fps_on": true,
		"res_scale": 0.5,
		"sfx_on": true,
		"music_on": true
	},
	"skins": {
		"equipped_skin_path": "",
		"unlocked_skin_paths": []
	}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string: String = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		print("Game Saved Successfully!")
	else:
		printerr("Failed to save game.")

func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json_string: String = file.get_as_text()
		file.close()

		var parsed_data = JSON.parse_string(json_string)
		if parsed_data is Dictionary:
			_merge_dict(data, parsed_data)
			print("Game Loaded Successfully!")

func _merge_dict(target: Dictionary, patch: Dictionary) -> void:
	for key in patch:
		if target.has(key) and target[key] is Dictionary and patch[key] is Dictionary:
			_merge_dict(target[key], patch[key])
		else:
			target[key] = patch[key]
