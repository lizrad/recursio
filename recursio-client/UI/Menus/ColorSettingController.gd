extends ScrollContainer

var _color_setting_scene = preload("res://UI/Menus/ColorSetting.tscn")

onready var _color_list = get_node("ColorList")
onready var _settings_tabs = get_node("..")

var color_settings :Array = []


func _ready() -> void:
	var header = ColorManager.header
	var colors = UserSettings.get_all_settings_for_header(header)
	for color in colors:
		var color_setting = _color_setting_scene.instance()
		_color_list.add_child(color_setting)
		color_setting.init(header, color)
		color_settings.append(color_setting)
	
	for i in range(1, color_settings.size()):
		var prev_color_setting : ColorSetting = color_settings[i-1]
		var cur_color_setting : ColorSetting = color_settings[i]
		prev_color_setting.set_next_focus(NodePath("../../"+cur_color_setting.name+"/ColorPickerButton"))
		cur_color_setting.set_previous_focus(NodePath("../../"+prev_color_setting.name+"/ColorPickerButton"))
	
	color_settings.front().set_previous_focus(NodePath("../../../../../BackButton"))
	color_settings.back().set_next_focus(NodePath("../../../../../BackButton"))


func get_next_focus_for_back_button() -> NodePath:
	return NodePath("../SettingsTabs/Colors/ColorList/"+color_settings.front().name+"/ColorPickerButton")


func get_previous_focus_for_back_button() -> NodePath:
	return NodePath("../SettingsTabs/Colors/ColorList/"+color_settings.back().name+"/ColorPickerButton")


func get_default_tab_focus() -> Node:
	return color_settings.front().get_color_picker()
