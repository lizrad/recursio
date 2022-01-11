extends Node

const PLAYER_MAX_COUNT = 2

var fog_of_war_enabled: bool = true

onready var level_scenes = [
	preload("res://Shared/Level/LevelH.tscn"),
	preload("res://Shared/Level/LevelHGap.tscn"),
	preload("res://Shared/Level/LevelPercentStar.tscn")
]

var config

func _init():
	config = ConfigFile.new()
	var err = config.load("res://Shared/constants.ini")

	if err != OK:
		Logger.error("Could not load shared config file!")


func get_value(section, key, default = null):
	return config.get_value(section, key, default)
