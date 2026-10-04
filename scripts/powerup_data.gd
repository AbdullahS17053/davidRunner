class_name PowerupData
extends Resource

enum PowerupType {
	SHIELD,
	SLINGSHOT,
	MAGNET,
	DOUBLE_COINS,
	SPEED_BOOST,
	HEAVENLY_LIFT
}

@export var type: PowerupType = PowerupType.SHIELD
@export var duration: float = 10.0
@export var model_scene: PackedScene
