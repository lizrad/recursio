extends ScrollContainer

var _color_setting_scene = preload("res://UI/Menus/ColorSetting.tscn")

var _color_header = "colors"
onready var _color_list = get_node("ColorList")


func _ready():
	var colors = UserSettings.get_all_settings_for_header(_color_header)
	for color in colors:
		var color_setting = _color_setting_scene.instance()
		_color_list.add_child(color_setting)
		color_setting.init(_color_header, color)
