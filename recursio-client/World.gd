extends Spatial

func _ready():
	Server.send_level_loaded()
