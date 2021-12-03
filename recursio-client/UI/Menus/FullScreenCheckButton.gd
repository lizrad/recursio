extends CheckButton


var settings setget set_settings


func set_settings(new_settings):
	settings = new_settings
	pressed = settings.get_setting("video", "fullscreen")


func _ready():
	connect("toggled", self, "_on_toggled")


func _on_toggled(is_enabled):
	OS.window_fullscreen = is_enabled
	settings.set_setting("video", "fullscreen", is_enabled)
