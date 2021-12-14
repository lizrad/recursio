extends HBoxContainer


onready var _color_picker_button : ColorPickerButton = get_node("ColorPickerButton")
onready var _label :Label = get_node("Label")


func init(header: String, key: String):
	var color_name = key.replace("_"," ").capitalize()
	name = color_name
	_label.text = color_name
	var color = Color(UserSettings.get_setting(header, key))
	_color_picker_button.color = color
