extends Control
class_name ButtonOverlay

signal button_pressed(button)

enum BUTTONS {
	NONE = 	0,
	UP = 	1,
	DOWN =  2,
	LEFT = 	4,
	RIGHT = 8
}

var _conf = { 
				BUTTONS.UP: "ui_select",
				BUTTONS.DOWN: "player_shoot",
				BUTTONS.LEFT: "player_melee",
				BUTTONS.RIGHT: "ui_cancel"
			}
var _triggers := []
var _close := false

func show_buttons(text: String, buttons: int, close_on_activation: bool = false) -> void:
	for button in BUTTONS.values():
		if buttons & button:
			$Buttons.get_node(str(button)).show()
			_triggers.append(_conf[button])

	$Label.text = text
	_close = close_on_activation

	set_process(true)
	visible = true


func hide_buttons() -> void:
	set_process(false)
	visible = false
	for button in $Buttons.get_children():
		button.hide()
	_triggers.clear()


func _process(_delta) -> void:
	for trigger in _triggers:
		if Input.is_action_pressed(trigger):
			var keys = _conf.keys()
			print("correct key")
			for key in _conf:
				if _conf[key] == trigger:
					print("emit trgger")
					emit_signal("button_pressed", key)
					break

			if _close:
				hide_buttons()
