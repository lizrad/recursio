extends Control


export var scale_mod := 8
export var scale_time := 0.5


onready var start_pos = $CountdownText.get_transform().get_origin()


var _text := ""
var _countdown_time: float = Constants.get_value("gameplay", "countdown_phase_seconds")


func _process(delta) -> void:
	_update_text(int(_countdown_time))
	_countdown_time -= delta
	# Hide if countdown is finished
	if _countdown_time <= 0.0:
		deactivate()


func activate() -> void:
	show()
	_countdown_time = Constants.get_value("gameplay","countdown_phase_seconds")


func deactivate() -> void:
	hide()
	_countdown_time = 0


func _update_text(sec: float) -> void:
	var text = str(sec) if sec > 0 else "GO!"
	
	if _text != text:
		_text = text
		
		if sec > 0:
			$ProgressSound.play()
		else:
			$GoSound.play()

		$CountdownText.text = text
		$Tween.interpolate_property($CountdownText, "rect_scale", Vector2.ONE, Vector2.ONE*scale_mod, scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property($CountdownText, "rect_position", start_pos, start_pos + $CountdownText.get_size()/2 - ($CountdownText.get_size() * scale_mod)/2, scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
