extends CenterContainer
class_name TutorialUIBottomElement


signal continue_pressed

var _continue_texture_scale_phase: float = 0.0
var _current_control = Controls.None

onready var _control_text: Label = get_node("ElementsList/ControlText")
onready var _space_1: Control = get_node("ElementsList/Space1")
onready var _control_texture: TextureRect = get_node("ElementsList/ControlTexture")
onready var _space_2: Control = get_node("ElementsList/Space2")
onready var _continue_texture: TextureRect = get_node("ElementsList/ContinueTexture")


enum Controls {
	None,
	Move,
	Look,
	Melee,
	Shoot,
	Dash,
	Swap
	}


var _continue_control_texture

var _continue_keyboard_texture = preload("res://Resources/Icons/keyboard/accept.png")
var _continue_ps_texture = preload("res://Resources/Icons/ps/accept.png")
var _continue_xbox_texture = preload("res://Resources/Icons/xbox/accept.png")


var _control_textures_dictionary: Dictionary

var _keyboard_textures_dictionary: Dictionary = {
	Controls.None : null,
	Controls.Move : preload("res://Resources/Icons/keyboard/move.png"),
	Controls.Look : preload("res://Resources/Icons/keyboard/look.png"),
	Controls.Melee : preload("res://Resources/Icons/keyboard/melee.png"),
	Controls.Shoot : preload("res://Resources/Icons/keyboard/shoot.png"),
	Controls.Dash : preload("res://Resources/Icons/keyboard/dash.png"),
	Controls.Swap : preload("res://Resources/Icons/keyboard/swap.png"),
}
var _ps_textures_dictionary: Dictionary = {
	Controls.None : null,
	Controls.Move : preload("res://Resources/Icons/ps/move.png"),
	Controls.Look : preload("res://Resources/Icons/ps/look.png"),
	Controls.Melee : preload("res://Resources/Icons/ps/melee.png"),
	Controls.Shoot : preload("res://Resources/Icons/ps/shoot.png"),
	Controls.Dash : preload("res://Resources/Icons/ps/dash.png"),
	Controls.Swap : preload("res://Resources/Icons/ps/swap.png"),
}
var _xbox_textures_dictionary: Dictionary = {
	Controls.None : null,
	Controls.Move : preload("res://Resources/Icons/xbox/move.png"),
	Controls.Look : preload("res://Resources/Icons/xbox/look.png"),
	Controls.Melee : preload("res://Resources/Icons/xbox/melee.png"),
	Controls.Shoot : preload("res://Resources/Icons/xbox/shoot.png"),
	Controls.Dash : preload("res://Resources/Icons/xbox/dash.png"),
	Controls.Swap : preload("res://Resources/Icons/xbox/swap.png"),
}

func _ready() -> void:
	var _error = InputManager.connect("controller_changed", self, "_on_controller_changed")
	_on_controller_changed(InputManager.get_current_controller())


func _input(_event: InputEvent) -> void:
	if not visible:
		return
	
	if Input.is_action_just_released("ui_accept"):
		emit_signal("continue_pressed")

func _process(delta):
	if _continue_texture.visible:
		_continue_texture_scale_phase += delta*3
		# moves between 0.8 and 1.0
		var scale = (0.95 + 0.05*((1+sin(_continue_texture_scale_phase))*0.5))
		_continue_texture.rect_scale = Vector2(1,1) * scale


func set_content(text: String, control = Controls.None, show_continue_texture: bool = false) -> void:
	assert(_control_textures_dictionary.has(control))
	_current_control = control
	_control_texture.texture = _control_textures_dictionary[control]
	if control == Controls.None:
		_space_1.hide()
		_control_texture.hide()
	else:
		_space_1.show()
		_control_texture.show()
	_control_text.text = text
	_continue_texture.texture = _continue_control_texture
	_continue_texture.visible = show_continue_texture
	_space_2.visible = show_continue_texture


func _on_controller_changed(controller: String) -> void:
	if controller == "ps":
		_control_textures_dictionary = _ps_textures_dictionary
		_continue_control_texture = _continue_ps_texture
	elif controller == "xbox":
		_control_textures_dictionary = _xbox_textures_dictionary
		_continue_control_texture = _continue_xbox_texture
	else:
		_control_textures_dictionary = _keyboard_textures_dictionary
		_continue_control_texture = _continue_keyboard_texture
	set_content(_control_text.text, _current_control, _continue_texture.visible)
