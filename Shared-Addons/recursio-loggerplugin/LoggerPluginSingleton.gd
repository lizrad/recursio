extends Node

const PLUGIN_NAME = "loggerplugin"
const GAME_RUNNNIG = "game_running"
const CONFIG_PATH = "res://addons/recursio-loggerplugin/logger.cfg"

func _ready():
	var config = _get_config()
	_toggle_game_running(config, true)
	Logger.default_configfile_path = CONFIG_PATH
	if config.has_section(Logger.PLUGIN_NAME):
		Logger.load_config()
	Logger.connect("module_added",self,"_on_module_added")

func _on_module_added():
	Logger.save_config()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		Logger.save_config()
		var config = _get_config()
		_toggle_game_running(config, false)
		get_tree().quit() # default behavior

func _get_config():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_PATH)
	return config

func _toggle_game_running(config, value):
	config.set_value(PLUGIN_NAME, GAME_RUNNNIG, value)
	config.save(CONFIG_PATH)
