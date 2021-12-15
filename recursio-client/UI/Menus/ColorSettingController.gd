extends ScrollContainer

var _color_setting_scene = preload("res://UI/Menus/ColorSetting.tscn")

onready var _color_list = get_node("ColorList")


func _ready():
	var header = ColorManager.header
	var colors = UserSettings.get_all_settings_for_header(header)
	for color in colors:
		var color_setting = _color_setting_scene.instance()
		_color_list.add_child(color_setting)
		color_setting.init(header, color)
