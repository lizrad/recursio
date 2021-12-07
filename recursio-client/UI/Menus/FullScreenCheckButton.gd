extends CheckButton


func _ready():
	connect("toggled", self, "_on_toggled")
	pressed = UserSettings.get_setting("video", "fullscreen")


func _on_toggled(is_enabled):
	OS.window_fullscreen = is_enabled
	UserSettings.set_setting("video", "fullscreen", is_enabled)
