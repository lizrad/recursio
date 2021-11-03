extends Control


export var scale_mod := 8
export var scale_time := 0.5

onready var start_pos = $CountdownText.get_transform().get_origin()

var _text := ""


func update_text(sec) -> void:
	var text = str(sec) if sec > 0 else "GO!"
	if _text != text:
		_text = text

		$CountdownText.text = text
		$Tween.interpolate_property($CountdownText, "rect_scale", Vector2.ONE, Vector2.ONE*scale_mod, scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.interpolate_property($CountdownText, "rect_position", start_pos, start_pos + $CountdownText.get_size()/2 - ($CountdownText.get_size() * scale_mod)/2, scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN)
		$Tween.start()
