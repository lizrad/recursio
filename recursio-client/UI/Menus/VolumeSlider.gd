extends HSlider


export var audio_bus_name := "Master"

onready var _bus := AudioServer.get_bus_index(audio_bus_name)

var settings setget set_settings


func _ready() -> void:
	connect("value_changed", self, "_on_value_changed")


func _on_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(_bus, linear2db(value))
	settings.set_setting("audio", audio_bus_name.to_lower() + "_volume", value)


func set_settings(new_settings):
	settings = new_settings
	value = settings.get_setting("audio", audio_bus_name.to_lower() + "_volume")
