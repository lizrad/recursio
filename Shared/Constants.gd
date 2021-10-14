extends Node

var config

func _init():
	config = ConfigFile.new()
	var err = config.load("res://Shared/constants.ini")

	if err != OK:
		Logger.error("Could not load shared config file!")


func get_value(section, key, default = null):
	return config.get_value(section, key, default)
