extends HSlider


export var audio_bus_name := "Master"

onready var _bus := AudioServer.get_bus_index(audio_bus_name)


func _ready() -> void:
	var _error = connect("value_changed", self, "_on_value_changed")
	value = UserSettings.get_setting("audio", audio_bus_name.to_lower() + "_volume")


func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_bus, linear2db(value))
	UserSettings.set_setting("audio", audio_bus_name.to_lower() + "_volume", value)
