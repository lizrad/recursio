extends HBoxContainer


onready var _color_picker_button : ColorPickerButton = get_node("ColorPickerButton")
onready var _label :Label = get_node("Label")

var _header
var _key


func _ready():
	_color_picker_button.connect("color_changed", self, "_on_color_changed")


func init(header: String, key: String):
	_header = header
	_key = key
	var color_name = key.replace("_"," ").capitalize()
	name = color_name
	_label.text = color_name
	var color = Color(UserSettings.get_setting(header, key))
	_color_picker_button.color = color

func _on_color_changed(color: Color):
	var color_string = "#" + color.to_html(false)
	UserSettings.set_setting(_header, _key, color_string)
