extends CheckButton


func _ready():
	var _error = connect("toggled", self, "_on_toggled")
	_error = UserSettings.connect("setting_changed", self, "_on_fullscreen_changed")

	pressed = UserSettings.get_setting("video", "fullscreen")


func _on_toggled(is_enabled):
	OS.window_fullscreen = is_enabled
	UserSettings.set_setting("video", "fullscreen", is_enabled)
	UserSettings.emit_signal("fullscreen_toggled", is_enabled)


func _on_fullscreen_changed(setting_header, setting_name, value):
	if setting_header == "video" and setting_name == "fullscreen":
		pressed = value
