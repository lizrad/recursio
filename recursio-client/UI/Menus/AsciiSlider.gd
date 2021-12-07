extends HSlider


func _ready() -> void:
	connect("value_changed", self, "_on_value_changed")
	value = UserSettings.get_setting("video", "ascii_size")


func _on_value_changed(value: float) -> void:
	UserSettings.set_setting("video", "ascii_size", value)
