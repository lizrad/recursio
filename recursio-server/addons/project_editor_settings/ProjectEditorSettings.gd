tool
extends EditorPlugin


const EDITOR_SECTION = "Editor"
const PROJECT_SECTION = "Project"

var _config_file: ConfigFile
var _editor_settings: EditorSettings

func _enter_tree():
	_editor_settings = get_editor_interface().get_editor_settings()
	_read_config_file()


func _read_config_file():
	_config_file = ConfigFile.new()
	var error = _config_file.load("res://addons/project_editor_settings/config.ini")
	
	if error != OK:
		printerr("PES: Could not load config file!")
	else:
		print("PES: Config file loaded")
		_set_settings()


func _set_settings():
	for section in _config_file.get_sections():
		for key in _config_file.get_section_keys(section):
			var value = _config_file.get_value(section, key)
			if section == EDITOR_SECTION:
				_editor_settings.set_setting(key, value)
			elif section == PROJECT_SECTION:
				ProjectSettings.set_setting(key, value)
