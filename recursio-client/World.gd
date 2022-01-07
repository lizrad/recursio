extends Spatial
class_name GameWorld

func level_set_up_done() -> void:
	Server.send_level_loaded()

func set_level(level: Level) -> void:
	$CharacterManager.set_level(level)


func toggle_player_input_pause(value: bool) -> void:
	$CharacterManager.toggle_player_input_pause(value)
