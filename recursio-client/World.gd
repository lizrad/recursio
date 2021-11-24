extends Spatial
class_name GameWorld

func _ready():
	Server.send_level_loaded()


func set_level(level: Level):
	$CharacterManager.set_level(level)
