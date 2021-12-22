extends CheckButton


onready var _stats_hud: Control = get_tree().get_root().get_node("StartScreen/StatsHUD")


func _ready():
	var _error = connect("toggled", self, "_on_toggled")

	pressed = UserSettings.get_setting("developer", "debug")


func _on_toggled(is_enabled):
	_stats_hud.visible = is_enabled
	UserSettings.set_setting("developer", "debug", is_enabled)
