extends CenterContainer
class_name TutorialUIBottomElement


signal continue_pressed

var _continue_texture_scale_phase: float = 0.0

onready var _control_text: Label = get_node("ElementsList/ControlText")
onready var _control_texture: TextureRect = get_node("ElementsList/ControlTexture")
onready var _continue_texture: TextureRect = get_node("ElementsList/ContinueTexture")


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

func _input(_event: InputEvent) -> void:
	if not visible:
		return
	
	if Input.is_action_just_pressed("ui_accept"):
		emit_signal("continue_pressed")

func _process(delta):
	if _continue_texture.visible:
		_continue_texture_scale_phase += delta*3
		# moves between 0.8 and 1.0
		var scale = (0.95 + 0.05*((1+sin(_continue_texture_scale_phase))*0.5))
		_continue_texture.rect_scale = Vector2(1,1) * scale


func set_content(text: String, control = Controls.None, show_continue_texture: bool = false) -> void:
	assert(_control_textures_dictionary.has(control))
	_control_texture.texture = _control_textures_dictionary[control]
	if control == Controls.None:
		_control_texture.hide()
	else:
		_control_texture.show()
	_control_text.text = text
	_continue_texture.visible = show_continue_texture
