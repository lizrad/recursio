extends Control
class_name ButtonOverlay

signal button_pressed

enum BUTTONS {
	NONE = 	0,
	UP = 	1,
	DOWN =  2,
	LEFT = 	4,
	RIGHT = 8
}

var _buttons := 0

func show_buttons(text, buttons) -> void:
	visible = true
	set_process(true)
	$Label.text = text
	# TODO: buttons to accept
	_buttons = buttons


func _process(delta) -> void:
	# TODO: check input by nice encapsulated input collection
	# left - melee
	# down - shoot
	# up - ui_select
	# right - ui_cancel
	if Input.is_action_pressed("ui_cancel"):
		emit_signal("button_pressed")
		visible = false
		set_process(false)
