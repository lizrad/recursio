extends Node

enum SoundType {
	CLICK,
	BACK
}

# TODO: Would be nice to map those in the inspector
var _sounds: Array = [
	preload("res://Resources/Audio/UI/Click.ogg"),
	preload("res://Resources/Audio/UI/Back.ogg")
]

onready var _player: AudioStreamPlayer = get_node("AudioStreamPlayer")


func play_sound(sound_type: int) -> void:	
	_player.stream = _sounds[sound_type]
	_player.play()
