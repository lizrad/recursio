extends CenterContainer
class_name TutorialUIBottomElement

onready var _control_text: Label = get_node("ElementsList/ControlText")
onready var _control_texture: TextureRect = get_node("ElementsList/ControlTexture")


enum Controls {
	None,
	Move,
	Look,
	Melee,
	Fire,
	Dash,
	Switch
	}

var _control_textures_dictionary: Dictionary = {
	Controls.None : null,
	Controls.Move : preload("res://icon.png"),
	Controls.Look : preload("res://icon.png"),
	Controls.Melee : preload("res://icon.png"),
	Controls.Fire : preload("res://icon.png"),
	Controls.Dash : preload("res://icon.png"),
	Controls.Switch : preload("res://icon.png"),
}


func set_content(text, control = Controls.None):
	assert(_control_textures_dictionary.has(control))
	_control_texture.texture = _control_textures_dictionary[control]
	if control == Controls.None:
		_control_texture.hide()
	else:
		_control_texture.show()
	_control_text.text = text
