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
	_error = _color_picker_button.connect("picker_created", self, "_on_picker_created")


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


# Code from: https://godotforums.org/discussion/25786/how-to-customize-a-colorpickerbutton-to-make-colors-selectable-with-a-keyboard-or-controller
func _on_picker_created() -> void:
	var picker = $ColorPickerButton.get_child(0).get_child(0)
	picker.get_child(1).get_child(1).set_focus_mode(1) # Eye dropper is a mouse tool
	# Allow sliders to acquire focus and reserve the SpinBox's LineEdit (child 0) for a mouse
	picker.get_child(4).get_child(0).get_child(1).set_focus_mode(2) # Red/Hue slider
	picker.get_child(4).get_child(0).get_child(2).get_child(0).set_focus_mode(1) # Red/Hue spinbox
	picker.get_child(4).get_child(1).get_child(1).set_focus_mode(2) # Green/Sat slider
	picker.get_child(4).get_child(1).get_child(2).get_child(0).set_focus_mode(1) # Green/Sat spinbox
	picker.get_child(4).get_child(2).get_child(1).set_focus_mode(2) # Blue/Value slider
	picker.get_child(4).get_child(2).get_child(2).get_child(0).set_focus_mode(1) # Blue/Value spinbox
	picker.get_child(4).get_child(4).get_child(1).hide() # Raw toggle; not a conventional feature
	picker.get_child(4).get_child(4).get_child(2).set_focus_mode(0) # Skip the hex '#' label!
	picker.get_child(4).get_child(4).get_child(3).set_focus_mode(1) # Hex LineEdit


func set_next_focus(focus: NodePath) -> void:
	$ColorPickerButton.focus_next = focus
	$ColorPickerButton.focus_neighbour_bottom = focus


func set_previous_focus(focus: NodePath) -> void:
	$ColorPickerButton.focus_previous = focus
	$ColorPickerButton.focus_neighbour_top = focus


func get_color_picker() -> Node:
	return $ColorPickerButton
