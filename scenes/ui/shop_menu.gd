extends Control
class_name SkinStoreUI

@export var available_skins: Array[SkinsData]

@export var error_label: Label
@export var skin_name_label: Label
@export var price_label: Label
@export var shop_menu_anims: AnimationPlayer
@export var menu_anims: AnimationPlayer
@export var purchase_btn: Button

@export var unlocked_icon: CompressedTexture2D
@export var equipped_icon: CompressedTexture2D
@export var locked_icon: CompressedTexture2D
@export var world_anims: AnimationPlayer
@export var player: Player

var current_skin_index: int = 0

func _ready() -> void:
	var unlocked_paths: Array = SaveManager.data["skins"]["unlocked_skin_paths"]
	for skin in available_skins:
		if skin.resource_path in unlocked_paths:
			skin.skin_unlocked = true

	update_ui()

func update_ui() -> void:
	if available_skins.is_empty():
		return
		
	var current_skin: SkinsData = available_skins[current_skin_index]
	_update_player_preview(current_skin)
		
	skin_name_label.text = current_skin.skin_name
	error_label.text = ""
	
	if current_skin.skin_unlocked:
		price_label.text = "Owned"
		
		if Global.equipped_skin == current_skin:
			purchase_btn.icon = equipped_icon
			purchase_btn.disabled = true
		else:
			purchase_btn.icon = unlocked_icon
			purchase_btn.disabled = false
	else:
		price_label.text = str(current_skin.skin_price)
		purchase_btn.icon = locked_icon
		purchase_btn.disabled = false

func _update_player_preview(skin_data: SkinsData) -> void:
	if not player or not player.visuals_node:
		return
		
	if player.current_skin_node:
		player.current_skin_node.queue_free()
		
	if skin_data and skin_data.skin_scene:
		player.current_skin_node = skin_data.skin_scene.instantiate()
		player.visuals_node.add_child(player.current_skin_node)
		
		if player.player_anims:
			player.player_anims.root_node = player.player_anims.get_path_to(player.current_skin_node)
		if player.animation_tree:
			player.animation_tree.active = false
			player.animation_tree.active = true

func _on_button_left_pressed() -> void:
	AudioManager.ui_click.play()
	current_skin_index -= 1
	if current_skin_index < 0:
		current_skin_index = available_skins.size() - 1
	update_ui()

func _on_button_right_pressed() -> void:
	AudioManager.ui_click.play()
	current_skin_index += 1
	if current_skin_index >= available_skins.size():
		current_skin_index = 0
	update_ui()

func _on_back_btn_pressed() -> void:
	AudioManager.ui_click.play()
	shop_menu_anims.play("exit")
	menu_anims.play("show")
	world_anims.play_backwards("store_camera")
	
	if player:
		player.apply_equipped_skin()

func _on_purchase_btn_pressed() -> void:
	if available_skins.is_empty():
		return
		
	var current_skin: SkinsData = available_skins[current_skin_index]
	
	if current_skin.skin_unlocked:
		Global.equipped_skin = current_skin
		SaveManager.data["skins"]["equipped_skin_path"] = current_skin.resource_path
		SaveManager.save_game()
		
		update_ui()
		error_label.text = "Skin Equipped!"
		return
		
	var current_bank: int = SaveManager.data["stats"]["total_coins"]
	if current_bank >= current_skin.skin_price:
		SaveManager.data["stats"]["total_coins"] -= current_skin.skin_price
		current_skin.skin_unlocked = true
		Global.equipped_skin = current_skin
		
		if not current_skin.resource_path in SaveManager.data["skins"]["unlocked_skin_paths"]:
			SaveManager.data["skins"]["unlocked_skin_paths"].append(current_skin.resource_path)
			
		SaveManager.data["skins"]["equipped_skin_path"] = current_skin.resource_path
		SaveManager.save_game()
		
		update_ui()
		error_label.text = "Purchase Successful!"
	else:
		error_label.text = "Not enough coins!"
