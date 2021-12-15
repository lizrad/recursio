extends Node

signal setting_changed(setting_header, setting_name)

export var always_apply_defaults_at_startup := false

var settings_config = ConfigFile.new()

const SETTINGS_PATH = "user://settings.ini"


func _ready():
	# Load previous settings
	var err = settings_config.load(SETTINGS_PATH)

	# If the file didn't load (first ever game start), save the defaults there initially
	if err != OK or always_apply_defaults_at_startup:
		settings_config.load("res://default-settings.ini") # this should never fail
		settings_config.save(SETTINGS_PATH)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.set_window_fullscreen(!OS.window_fullscreen)
		set_setting("video", "fullscreen", OS.window_fullscreen)


func get_setting(setting_header, setting_name, default = null):
	return settings_config.get_value(setting_header, setting_name, default)


func set_setting(setting_header, setting_name, value):
	settings_config.set_value(setting_header, setting_name, value)
	settings_config.save(SETTINGS_PATH)
	emit_signal("setting_changed", setting_header, setting_name, value)


func get_all_settings_for_header(setting_header):
	return settings_config.get_section_keys(setting_header)
