extends CheckButton


func _ready():
	var _error = connect("toggled", self, "_on_toggled")

	pressed = UserSettings.get_setting("developer", "debug")


func _on_toggled(is_enabled):
	if get_tree().get_root().has_node("StatsHUD"):
		get_tree().get_root().get_node("StatsHUD").visible = is_enabled
	UserSettings.set_setting("developer", "debug", is_enabled)
