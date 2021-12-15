extends HBoxContainer
class_name ColorSetting


onready var _color_picker_button : ColorPickerButton = get_node("ColorPickerButton")
onready var _label :Label = get_node("Label")

var _header
var _key


func _ready() -> void:
	# listening to popup_closed instead of color_changed so it really only saves 
	# to file when the user decided
	var _error = _color_picker_button.connect("popup_closed", self, "_on_popup_closed")


func init(header: String, key: String) -> void:
	_header = header
	_key = key
	var color_name = key.replace("_"," ").capitalize()
	name = _key
	_label.text = color_name
	var color = Color(UserSettings.get_setting(header, key))
	_color_picker_button.color = color


func _on_popup_closed() -> void:
	var color = _color_picker_button.color
	var color_string = "#" + color.to_html(false)
	UserSettings.set_setting(_header, _key, color_string)
	ColorManager.color_changed(_key)


func set_next_focus(focus: NodePath) -> void:
	$ColorPickerButton.focus_next = focus
	$ColorPickerButton.focus_neighbour_bottom = focus


func set_previous_focus(focus: NodePath) -> void:
	$ColorPickerButton.focus_previous = focus
	$ColorPickerButton.focus_neighbour_top = focus


func get_color_picker() -> Node:
	return $ColorPickerButton
