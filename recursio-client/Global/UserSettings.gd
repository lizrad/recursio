extends Node

signal setting_changed(setting_header, setting_name)

export var always_apply_defaults_at_startup := false

var settings_config = ConfigFile.new()
var default_settings_config = ConfigFile.new()

const SETTINGS_PATH = "user://settings.ini"
const DEFAULT_SETTINGS_PATH = "res://default-settings.ini"


func _ready():
	# Load previous settings
	var err = settings_config.load(SETTINGS_PATH)
	var _err = default_settings_config.load(DEFAULT_SETTINGS_PATH) # this should never fail

	# If the file didn't load (first ever game start), save the defaults there initially
	if err != OK or always_apply_defaults_at_startup:
		settings_config = default_settings_config
		settings_config.save(SETTINGS_PATH)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.set_window_fullscreen(!OS.window_fullscreen)
		set_setting("video", "fullscreen", OS.window_fullscreen)


func get_setting(setting_header, setting_name, default = null):
	return settings_config.get_value(setting_header, setting_name, get_default_setting(setting_header, setting_name, default))


func get_default_setting(setting_header, setting_name, default = null):
	return default_settings_config.get_value(setting_header, setting_name, default)


func set_setting(setting_header, setting_name, value):
	settings_config.set_value(setting_header, setting_name, value)
	settings_config.save(SETTINGS_PATH)
	emit_signal("setting_changed", setting_header, setting_name, value)


func get_all_settings_for_header(setting_header):
	return default_settings_config.get_section_keys(setting_header)
