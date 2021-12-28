extends Control
class_name ButtonOverlay

signal button_pressed(button)

enum BUTTONS {
	NONE = 	0,
	UP = 	1,
	DOWN = 	2,
	LEFT = 	4,
	RIGHT = 8
}

var _conf = { 
				BUTTONS.UP: "ui_select",
				BUTTONS.DOWN: "player_shoot",
				BUTTONS.LEFT: "player_melee",
				BUTTONS.RIGHT: "player_switch"
			}
var _triggers := []
var _close := 0


func _ready() -> void:
	var _error = InputManager.connect("controller_changed", self, "_on_controller_changed")
	_on_controller_changed(InputManager.get_current_controller())


func _on_controller_changed(controller) -> void:
	for sprite in get_tree().get_nodes_in_group("controller"):
		sprite.hide()

	if has_node(controller):
		get_node(controller).visible = true


# displays a dialog with given marked buttons as bitmask
# supports array for text: are added in enum order
# specify buttons which close the dialog
func show_buttons(texts, buttons: int, close_on_activation: int = 0) -> void:
	var i = 0
	for button in BUTTONS.values():
		if buttons & button:
			_triggers.append(_conf[button])
			$Labels.get_node("Label" + str(button)).text = texts[i]
			i += 1

	_close = close_on_activation

	set_process(true)
	visible = true


func hide_buttons() -> void:
	set_process(false)
	visible = false
	for label in $Labels.get_children():
		label.text = ""
	_triggers.clear()


func _process(_delta) -> void:
	for trigger in _triggers:
		if Input.is_action_pressed(trigger):
			for key in _conf:
				if _conf[key] == trigger:
					emit_signal("button_pressed", key)
					if _close & key:
						hide_buttons()
					break
