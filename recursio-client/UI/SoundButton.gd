extends Button
class_name SoundButton

export(SoundManager.SoundType) var sound_type: int = SoundManager.SoundType.CLICK


func _ready():
	var _err = self.connect("pressed", self, "_on_button_pressed")

func _on_button_pressed() -> void:
	SoundManager.play_sound(sound_type)
