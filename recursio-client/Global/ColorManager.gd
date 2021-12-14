extends Node

var _header = "colors"


func _get_color(color_name: String) -> Color:
	return Color(UserSettings.get_setting(_header, color_name))


func color_object_by_property(color_name: String, object: Object, property: String):
	assert(is_instance_valid(object))
	var color = _get_color(color_name)
	object.set(property, color)


# this expect the color to be the last argument in the called method
func color_object_by_method(color_name: String, object: Object, method: String, additional_method_args: Array):
	var color = _get_color(color_name)
	additional_method_args.append(color)
	object.callv(method, additional_method_args)
