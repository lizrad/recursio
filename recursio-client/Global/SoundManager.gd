extends Node

enum SoundType {
	CLICK,
	BACK
}

# TODO: Would be nice to map those in the inspector
var _ui_sounds: Array = [
	preload("res://Resources/Audio/UI/Click.ogg"),
	preload("res://Resources/Audio/UI/Back.ogg")
]

onready var _ui_player: AudioStreamPlayer = get_node("UIPlayer")


func play_sound_ui(sound_type: int) -> void:	
	_ui_player.stream = _ui_sounds[sound_type]
	_ui_player.play()
