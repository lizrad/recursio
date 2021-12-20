extends Button
class_name SoundButton

enum SoundType {
	CLICK,
	BACK
}

export(SoundType) var sound_type: int = SoundType.CLICK

var _sounds: Array = [
	preload("res://Resources/Audio/UI/Click.ogg"),
	preload("res://Resources/Audio/UI/Back.ogg")
]

onready var _player: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready():
	var _err = self.connect("pressed", self, "_on_button_pressed")
	_player.stream = _sounds[sound_type]


func _on_button_pressed():
	_player.play()
