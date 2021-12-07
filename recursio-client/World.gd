extends Spatial
class_name GameWorld

func level_set_up_done():
	Server.send_level_loaded()

func set_level(level: Level):
	$CharacterManager.set_level(level)
