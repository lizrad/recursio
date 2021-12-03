extends PanelContainer

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
	
	$SettingsList/BackButton.connect("pressed", self, "_on_back_pressed")
	
	# Allow nodes which set a setting to access the config via this node
	for node in get_tree().get_nodes_in_group("Setting"):
		node.set("settings", self)


func _on_back_pressed():
	hide()


func get_setting(setting_header, setting_name, default = null):
	return settings_config.get_value(setting_header, setting_name, default)


func set_setting(setting_header, setting_name, value):
	settings_config.set_value(setting_header, setting_name, value)
	settings_config.save(SETTINGS_PATH)
