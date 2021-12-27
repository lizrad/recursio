extends Control


export var scale_mod := 300
export var scale_time := 0.5

var _text := ""
var _countdown_time: float = 0

func _ready() -> void:
	set_physics_process(false)

func _process(delta) -> void:
	_update_text(int(_countdown_time))
	_countdown_time -= delta
	# Hide if countdown is finished
	if _countdown_time <= 0.0:
		deactivate()


func activate() -> void:
	show()
	_countdown_time = Constants.get_value("gameplay","countdown_phase_seconds")
	set_physics_process(true)


func deactivate() -> void:
	hide()
	_countdown_time = 0
	set_physics_process(false)


func _update_text(sec: float) -> void:
	var text = str(sec) if sec > 0 else "GO!"
	if _text != text:
		_text = text
		if sec > 0:
			$ProgressSound.play()
		else:
			$GoSound.play()
		$CountdownText.text = text
		$Tween.interpolate_property($CountdownText.get("custom_fonts/font"), "size", 30, scale_mod, scale_time, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT )
		$Tween.start()
